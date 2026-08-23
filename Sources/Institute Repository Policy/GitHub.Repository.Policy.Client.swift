import Institute_Repository_Policy
import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension RepositoryPolicy {
    public struct GitHubClient: Sendable {
        /// Every way one client operation refuses: an HTTP status outside
        /// the operation's contract, a transport failure underneath the
        /// request, a response body that does not decode, a response that
        /// violates the operation's preconditions, or a refusal raised by
        /// the Issue grammar during a compaction.
        public enum Error: Swift.Error, CustomStringConvertible, Sendable {
            case http(method: String, path: String, status: Int, response: String)
            case transport(path: String, message: String)
            case decoding(path: String, message: String)
            case precondition(String)
            case issue(RepositoryPolicy.Issue.Error)

            public var description: String {
                switch self {
                case .http(let method, let path, let status, let response):
                    return "\(method) \(path) returned HTTP \(status): \(response)"

                case .transport(let path, let message):
                    return "\(path): transport failure: \(message)"

                case .decoding(let path, let message):
                    return "\(path): response did not decode: \(message)"

                case .precondition(let message):
                    return message

                case .issue(let error):
                    return "issue grammar refusal: \(error)"
                }
            }
        }

        private let token: String
        private let baseURL: URL
        private let execute:
            // REASON: The injectable URLSession boundary preserves heterogeneous transport
            // failures for retry classification.
            // swiftlint:disable:next no_any_protocol_existential
            @Sendable (URLRequest) async throws(any Swift.Error) -> (
                Data, URLResponse
            )
        private let maximumAttempts: Int
        private let delaySeconds: Int

        public init(
            token: String,
            baseURL: URL,
            maximumAttempts: Int = 4,
            delaySeconds: Int = 2,
            execute:
                // REASON: The injectable URLSession boundary preserves heterogeneous transport
                // failures for retry classification.
                // swiftlint:disable:next no_any_protocol_existential
                @escaping @Sendable (URLRequest) async throws(any Swift.Error) -> (
                    Data, URLResponse
                ) = { try await URLSession.shared.data(for: $0) }
        ) {
            self.token = token
            self.baseURL = baseURL
            self.maximumAttempts = maximumAttempts
            self.delaySeconds = delaySeconds
            self.execute = execute
        }

        public func repositories(
            organization: String
        ) async throws(Error) -> [Repository] {
            try await callerWaveRepositories(organization: organization).repositories
        }

        public func callerWaveCapacity(
            requiredRequests: Int
        ) async throws(Error) -> Repository.Policy.Caller.Wave.Capacity {
            guard requiredRequests > 0 else {
                throw .precondition("caller-wave required request capacity must be positive")
            }
            let path = "/rate_limit"
            let response = try await request(method: "GET", path: path)
            guard response.status == 200 else {
                throw error(method: "GET", path: path, response: response)
            }
            let limit = try decode(WaveRateLimit.self, from: response.data, path: path)
            return .init(
                remaining: limit.resources.core.remaining,
                required: requiredRequests,
                resetAt: limit.resources.core.reset
            )
        }

        public func callerWaveRepositories(
            organization: String
        ) async throws(Error) -> Repository.Policy.Caller.Wave.Listing {
            let expectedBefore = try await publicRepositoryCount(organization: organization)
            var page = 1
            var result = [Repository]()
            var visited: Set<Int> = []
            while true {
                guard visited.insert(page).inserted else {
                    throw .precondition(
                        "\(organization): repository pagination repeated page \(page)"
                    )
                }
                let path = "/orgs/\(organization)/repos?type=public&per_page=100&page=\(page)"
                let response = try await request(method: "GET", path: path)
                guard response.status == 200 else {
                    throw error(method: "GET", path: path, response: response)
                }
                let repositories = try decode([Repository].self, from: response.data, path: path)
                result.append(contentsOf: repositories)
                guard let next = try nextPage(response.headers) else { break }
                guard next == page + 1 else {
                    throw .precondition(
                        "\(organization): repository pagination advanced from page \(page) to \(next)"
                    )
                }
                page = next
            }
            let expectedAfter = try await publicRepositoryCount(organization: organization)
            guard expectedBefore == expectedAfter else {
                throw .precondition(
                    "\(organization): public repository count moved from \(expectedBefore) "
                        + "to \(expectedAfter) during enumeration"
                )
            }
            guard result.count == expectedAfter else {
                throw .precondition(
                    "\(organization): enumerated \(result.count) public repositories; "
                        + "organization reports \(expectedAfter)"
                )
            }
            guard Set(result.map(\.id)).count == result.count,
                Set(result.map { $0.fullName.lowercased() }).count == result.count
            else {
                throw .precondition("\(organization): repository pagination returned duplicates")
            }
            return .init(repositories: result, expected: expectedAfter)
        }

        public func repository(_ fullName: String) async throws(Error) -> Repository {
            let path = "/repos/\(fullName)"
            let response = try await request(method: "GET", path: path)
            guard response.status == 200 else {
                throw error(method: "GET", path: path, response: response)
            }
            return try decode(Repository.self, from: response.data, path: path)
        }

        public func rootManifestKind(_ fullName: String) async throws(Error) -> String? {
            let path = "/repos/\(fullName)/contents/Package.swift"
            let response = try await request(method: "GET", path: path)
            if response.status == 404 { return nil }
            guard response.status == 200 else {
                throw error(method: "GET", path: path, response: response)
            }
            return try decode(Content.self, from: response.data, path: path).type
        }

        public func callerWaveManifest(
            _ fullName: String,
            head: String
        ) async throws(Error) -> Repository.Policy.Caller.Wave.Manifest? {
            let path = "/repos/\(fullName)/contents/Package.swift?ref=\(head)"
            let response = try await request(method: "GET", path: path)
            if response.status == 404 { return nil }
            guard response.status == 200 else {
                throw error(method: "GET", path: path, response: response)
            }
            let content = try decode(WaveContent.self, from: response.data, path: path)
            return .init(kind: content.type, blob: content.sha)
        }

        /// Reads one current Issue body and its HTTP entity tag. The tag and
        /// body digest are both required before an apply operation can begin.
        public func issueSnapshot(
            _ fullName: String,
            number: Int
        ) async throws(Error) -> Issue.Snapshot {
            let path = "/repos/\(fullName)/issues/\(number)"
            let response = try await request(method: "GET", path: path)
            guard response.status == 200 else {
                throw error(method: "GET", path: path, response: response)
            }
            guard let revision = response.headers["Etag"] ?? response.headers["ETag"] else {
                throw Error.precondition(
                    "\(fullName)#\(number): GitHub did not return an entity tag"
                )
            }
            let issue = try decode(RemoteIssue.self, from: response.data, path: path)
            let state: Issue.NativeState
            if issue.state == "open" {
                state = .open
            } else if issue.stateReason == "not_planned" {
                state = .notPlanned
            } else if issue.stateReason == "duplicate" {
                state = .duplicate
            } else {
                state = .completed
            }
            return .init(
                coordinate: issue.htmlURL,
                revision: revision,
                body: issue.body ?? "",
                native: .init(state: state)
            )
        }

        /// Plans a compaction from one current body. `apply: false` is fully
        /// report-only. On apply, the current GET compares the caller's
        /// revision and digest immediately before the one body PATCH; GitHub
        /// does not support conditional unsafe REST requests. The checkpoint
        /// comment is posted only after that PATCH succeeds.
        public func compactIssue(
            _ fullName: String,
            number: Int,
            guard expected: Issue.Guard,
            apply: Bool
        ) async throws(Error) -> Issue.Compaction? {
            let snapshot = try await issueSnapshot(fullName, number: number)
            let plan: Issue.Compaction?
            do throws(Issue.Error) {
                plan = try Issue.Compactor.plan(snapshot: snapshot, guard: expected)
            } catch {
                throw Error.issue(error)
            }
            guard let plan else { return nil }
            guard apply else { return plan }

            let issuePath = "/repos/\(fullName)/issues/\(number)"
            let update = try await request(
                method: "PATCH",
                path: issuePath,
                body: encode(["body": plan.body])
            )
            guard update.status == 200 else {
                throw error(method: "PATCH", path: issuePath, response: update)
            }
            let commentPath = "\(issuePath)/comments"
            let comment = try await request(
                method: "POST",
                path: commentPath,
                body: encode(["body": plan.checkpoint])
            )
            guard comment.status == 201 else {
                throw error(method: "POST", path: commentPath, response: comment)
            }
            return plan
        }

        public func surfaceFiles(_ fullName: String) async throws(Error) -> [String: String] {
            var pending = [
                ".github/workflows",
                ".github/actions",
                ".github/ISSUE_TEMPLATE",
            ]
            var files = [String: String]()
            while let path = pending.popLast() {
                let response = try await request(
                    method: "GET",
                    path: "/repos/\(fullName)/contents/\(path)"
                )
                if response.status == 404 {
                    continue
                }
                guard response.status == 200 else {
                    throw error(
                        method: "GET",
                        path: "/repos/\(fullName)/contents/\(path)",
                        response: response
                    )
                }

                // A directory listing decodes as an array; a file decodes
                // as a single object. Probe the array shape first and fall
                // through to the file shape when it does not apply.
                let entries: [Content]?
                do {
                    entries = try JSONDecoder().decode([Content].self, from: response.data)
                } catch {
                    entries = nil
                }
                if let entries {
                    for entry in entries.sorted(by: { $0.path < $1.path }).reversed() {
                        if entry.type == "dir" {
                            pending.append(entry.path)
                        } else if entry.type == "file", isGovernedSurface(path: entry.path) {
                            pending.append(entry.path)
                        }
                    }
                    continue
                }

                let content = try decode(
                    Content.self,
                    from: response.data,
                    path: "/repos/\(fullName)/contents/\(path)"
                )
                guard content.type == "file", isGovernedSurface(path: content.path) else {
                    continue
                }
                guard
                    content.encoding == "base64",
                    let encoded = content.content,
                    let data = Data(
                        base64Encoded: encoded,
                        options: .ignoreUnknownCharacters
                    ),
                    let source = String(data: data, encoding: .utf8)
                else {
                    throw Error.precondition(
                        "\(fullName): could not decode governed file \(content.path)"
                    )
                }
                files[content.path] = source
            }
            return files
        }

        public func vulnerabilityReporting(
            _ fullName: String
        ) async throws(Error) -> VulnerabilityReporting {
            let path = "/repos/\(fullName)/private-vulnerability-reporting"
            let response = try await request(method: "GET", path: path)
            if response.status == 404 { return .disabled }
            guard response.status == 200 else {
                throw error(method: "GET", path: path, response: response)
            }
            let state = try decode(
                PrivateVulnerabilityReporting.self,
                from: response.data,
                path: path
            )
            return state.enabled ? .enabled : .disabled
        }

        public func enableVulnerabilityReporting(_ fullName: String) async throws(Error) {
            let path = "/repos/\(fullName)/private-vulnerability-reporting"
            let response = try await request(method: "PUT", path: path)
            guard response.status == 204 else {
                throw error(method: "PUT", path: path, response: response)
            }
        }

        public func callerWaveRepository(
            _ fullName: String
        ) async throws(Error) -> Repository.Policy.Caller.Wave.Repository {
            let path = "/repos/\(fullName)"
            let response = try await request(method: "GET", path: path)
            guard response.status == 200 else {
                throw error(method: "GET", path: path, response: response)
            }
            let repository = try decode(WaveRepository.self, from: response.data, path: path)
            return .init(
                id: repository.id,
                visibility: repository.visibility,
                archived: repository.archived,
                disabled: repository.disabled,
                defaultBranch: repository.defaultBranch
            )
        }

        public func callerWaveHead(_ fullName: String) async throws(Error) -> String {
            let path = "/repos/\(fullName)/git/ref/heads/main"
            let response = try await request(method: "GET", path: path)
            guard response.status == 200 else {
                throw error(method: "GET", path: path, response: response)
            }
            return try decode(WaveReference.self, from: response.data, path: path).object.sha
        }

        public func callerWaveSource(
            _ fullName: String,
            head: String
        ) async throws(Error)
            -> Repository.Policy.Caller.Wave.CallerSource
        {
            guard let source = try await callerWaveSourceIfPresent(fullName, head: head) else {
                throw Error.precondition("\(fullName): required package caller is absent")
            }
            return source
        }

        public func callerWaveSourceIfPresent(
            _ fullName: String,
            head: String
        ) async throws(Error)
            -> Repository.Policy.Caller.Wave.CallerSource?
        {
            let path = "/repos/\(fullName)/contents/.github/workflows/ci.yml?ref=\(head)"
            let response = try await request(method: "GET", path: path)
            if response.status == 404 { return nil }
            guard response.status == 200 else {
                throw error(method: "GET", path: path, response: response)
            }
            let content = try decode(WaveContent.self, from: response.data, path: path)
            guard content.encoding == "base64",
                let bytes = Data(
                    base64Encoded: content.content,
                    options: .ignoreUnknownCharacters
                )
            else {
                throw Error.precondition("\(fullName): caller content is not base64")
            }
            return .init(blob: content.sha, bytes: bytes)
        }

        public func callerWaveRulesets(
            _ fullName: String
        ) async throws(Error)
            -> [Repository.Policy.Caller.Wave.RulesetReference]
        {
            var page = 1
            var result: [Repository.Policy.Caller.Wave.RulesetReference] = []
            var visited: Set<Int> = []
            while true {
                guard visited.insert(page).inserted else {
                    throw .precondition("\(fullName): ruleset pagination repeated page \(page)")
                }
                let path = "/repos/\(fullName)/rulesets?per_page=100&page=\(page)"
                let response = try await request(method: "GET", path: path)
                guard response.status == 200 else {
                    throw error(method: "GET", path: path, response: response)
                }
                result.append(
                    contentsOf: try decode([WaveRuleset].self, from: response.data, path: path)
                        .map { .init(id: $0.id, name: $0.name) }
                )
                guard let next = try nextPage(response.headers) else { return result }
                guard next == page + 1 else {
                    throw .precondition(
                        "\(fullName): ruleset pagination advanced from page \(page) to \(next)"
                    )
                }
                page = next
            }
        }

        public func callerWaveRuleset(
            _ fullName: String,
            id: Int64
        ) async throws(Error) -> Data {
            let path = "/repos/\(fullName)/rulesets/\(id)"
            let response = try await request(method: "GET", path: path)
            guard response.status == 200 else {
                throw error(method: "GET", path: path, response: response)
            }
            return response.data
        }

        public func callerWaveReplaceRuleset(
            _ fullName: String,
            id: Int64,
            payload: Data
        ) async throws(Error) {
            let path = "/repos/\(fullName)/rulesets/\(id)"
            let response = try await request(method: "PUT", path: path, body: payload)
            guard response.status == 200 else {
                throw error(method: "PUT", path: path, response: response)
            }
        }

        public func callerWaveCreateRuleset(
            _ fullName: String,
            payload: Data
        ) async throws(Error) -> Int64 {
            let path = "/repos/\(fullName)/rulesets"
            let response = try await request(method: "POST", path: path, body: payload)
            guard response.status == 201 else {
                throw error(method: "POST", path: path, response: response)
            }
            return try decode(WaveRuleset.self, from: response.data, path: path).id
        }

        public func callerWaveCreateBlob(
            _ fullName: String,
            content: Data
        ) async throws(Error) -> String {
            let path = "/repos/\(fullName)/git/blobs"
            let body = encodeObject([
                "content": content.base64EncodedString(),
                "encoding": "base64",
            ])
            let response = try await request(method: "POST", path: path, body: body)
            guard response.status == 201 else {
                throw error(method: "POST", path: path, response: response)
            }
            return try decode(WaveSHA.self, from: response.data, path: path).sha
        }

        public func callerWaveCreateCommit(
            _ fullName: String,
            parent: String,
            blob: String,
            message: String
        ) async throws(Error) -> String {
            let commitPath = "/repos/\(fullName)/git/commits/\(parent)"
            let commitResponse = try await request(method: "GET", path: commitPath)
            guard commitResponse.status == 200 else {
                throw error(method: "GET", path: commitPath, response: commitResponse)
            }
            let baseTree = try decode(
                WaveCommit.self,
                from: commitResponse.data,
                path: commitPath
            ).tree.sha

            let treePath = "/repos/\(fullName)/git/trees"
            let treeBody = encodeObject([
                "base_tree": baseTree,
                "tree": [
                    [
                        "path": ".github/workflows/ci.yml",
                        "mode": "100644",
                        "type": "blob",
                        "sha": blob,
                    ]
                ],
            ])
            let treeResponse = try await request(method: "POST", path: treePath, body: treeBody)
            guard treeResponse.status == 201 else {
                throw error(method: "POST", path: treePath, response: treeResponse)
            }
            let tree = try decode(WaveSHA.self, from: treeResponse.data, path: treePath).sha

            let createPath = "/repos/\(fullName)/git/commits"
            let createBody = encodeObject([
                "message": message,
                "tree": tree,
                "parents": [parent],
            ])
            let createResponse = try await request(
                method: "POST",
                path: createPath,
                body: createBody
            )
            guard createResponse.status == 201 else {
                throw error(method: "POST", path: createPath, response: createResponse)
            }
            return try decode(WaveSHA.self, from: createResponse.data, path: createPath).sha
        }

        public func callerWaveMoveMain(
            _ fullName: String,
            to head: String
        ) async throws(Error) {
            let path = "/repos/\(fullName)/git/refs/heads/main"
            let response = try await request(
                method: "PATCH",
                path: path,
                body: encodeObject(["sha": head, "force": false])
            )
            guard response.status == 200 else {
                throw error(method: "PATCH", path: path, response: response)
            }
        }

        public func uniformityWaveFileIfPresent(
            _ fullName: String,
            path filePath: String,
            head: String
        ) async throws(Error)
            -> Repository.Policy.Uniformity.Wave.File?
        {
            let path = "/repos/\(fullName)/contents/\(filePath)?ref=\(head)"
            let response = try await request(method: "GET", path: path)
            if response.status == 404 { return nil }
            guard response.status == 200 else {
                throw error(method: "GET", path: path, response: response)
            }
            let content = try decode(WaveContent.self, from: response.data, path: path)
            guard content.type == "file", content.encoding == "base64",
                let bytes = Data(
                    base64Encoded: content.content,
                    options: .ignoreUnknownCharacters
                )
            else {
                throw Error.precondition(
                    "\(fullName): \(filePath) content is not a base64 regular file"
                )
            }
            return .init(blob: content.sha, bytes: bytes)
        }

        public func uniformityWaveCreateCommit(
            _ fullName: String,
            parent: String,
            gitignoreBlob: String,
            deletions: [String],
            message: String
        ) async throws(Error) -> String {
            let commitPath = "/repos/\(fullName)/git/commits/\(parent)"
            let commitResponse = try await request(method: "GET", path: commitPath)
            guard commitResponse.status == 200 else {
                throw error(method: "GET", path: commitPath, response: commitResponse)
            }
            let baseTree = try decode(
                WaveCommit.self,
                from: commitResponse.data,
                path: commitPath
            ).tree.sha

            var entries: [[String: Any]] = [
                [
                    "path": Repository.Policy.Uniformity.Wave.Shape
                        .gitignorePath,
                    "mode": "100644",
                    "type": "blob",
                    "sha": gitignoreBlob,
                ]
            ]
            for deletion in deletions {
                // A null sha in a tree entry deletes the path from the
                // base tree; this is the API's exact deletion form.
                entries.append(
                    [
                        "path": deletion,
                        "mode": "100644",
                        "type": "blob",
                        "sha": NSNull(),
                    ]
                )
            }
            let treePath = "/repos/\(fullName)/git/trees"
            let treeBody = encodeObject(
                [
                    "base_tree": baseTree,
                    "tree": entries,
                ]
            )
            let treeResponse = try await request(method: "POST", path: treePath, body: treeBody)
            guard treeResponse.status == 201 else {
                throw error(method: "POST", path: treePath, response: treeResponse)
            }
            let tree = try decode(WaveSHA.self, from: treeResponse.data, path: treePath).sha

            let createPath = "/repos/\(fullName)/git/commits"
            let createBody = encodeObject(
                [
                    "message": message,
                    "tree": tree,
                    "parents": [parent],
                ]
            )
            let createResponse = try await request(
                method: "POST",
                path: createPath,
                body: createBody
            )
            guard createResponse.status == 201 else {
                throw error(method: "POST", path: createPath, response: createResponse)
            }
            return try decode(WaveSHA.self, from: createResponse.data, path: createPath).sha
        }

        public func callerWavePause(attempt: Int) async {
            await pause(seconds: delaySeconds << max(0, attempt - 1))
        }

        private func request(
            method: String,
            path: String,
            body: Data? = nil,
            retries: Bool? = nil
        ) async throws(Error) -> (data: Data, status: Int, headers: [String: String]) {
            guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
                preconditionFailure("Invalid GitHub API path: \(path)")
            }
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
            request.setValue("swift-institute-repository-policy", forHTTPHeaderField: "User-Agent")
            if let body {
                request.httpBody = body
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } else if method == "PUT" {
                request.httpBody = Data()
                request.setValue("0", forHTTPHeaderField: "Content-Length")
            }
            let mayRetry = retries ?? (method == "GET")
            var attempt = 1
            while true {
                let data: Data
                let anyResponse: URLResponse
                do {
                    (data, anyResponse) = try await execute(request)
                } catch {
                    guard mayRetry, attempt < maximumAttempts else {
                        throw Error.transport(path: path, message: String(describing: error))
                    }
                    await callerWavePause(attempt: attempt)
                    attempt += 1
                    continue
                }
                guard let response = anyResponse as? HTTPURLResponse else {
                    throw Error.transport(path: path, message: "response is not HTTP")
                }
                let headers = response.allHeaderFields.reduce(into: [String: String]()) {
                    $0[String(describing: $1.key)] = String(describing: $1.value)
                }
                if mayRetry, retryable(response.statusCode), attempt < maximumAttempts {
                    let seconds = retryDelay(headers: headers, attempt: attempt)
                    await pause(seconds: seconds)
                    attempt += 1
                    continue
                }
                return (data, response.statusCode, headers)
            }
        }

        private func publicRepositoryCount(organization: String) async throws(Error) -> Int {
            let path = "/orgs/\(organization)"
            let response = try await request(method: "GET", path: path)
            guard response.status == 200 else {
                throw error(method: "GET", path: path, response: response)
            }
            return try decode(WaveOrganization.self, from: response.data, path: path).publicRepos
        }

        private func nextPage(_ headers: [String: String]) throws(Error) -> Int? {
            guard
                let link = headers.first(where: { $0.key.lowercased() == "link" })?.value,
                let field = link.split(separator: ",").first(where: { $0.contains("rel=\"next\"") })
            else { return nil }
            guard
                let start = field.firstIndex(of: "<"),
                let end = field[start...].firstIndex(of: ">"),
                let components = URLComponents(
                    string: Swift.String(field[field.index(after: start)..<end])
                ),
                let page = components.queryItems?.first(where: { $0.name == "page" })?.value,
                let value = Swift.Int(page),
                value > 0
            else {
                throw .precondition("GitHub pagination Link field was invalid")
            }
            return value
        }

        private func retryable(_ status: Int) -> Bool {
            status == 429 || status == 500 || status == 502 || status == 503 || status == 504
        }

        private func retryDelay(headers: [String: String], attempt: Int) -> Int {
            let retryAfter = headers.first { $0.key.lowercased() == "retry-after" }?.value
            return retryAfter.flatMap(Int.init) ?? delaySeconds << max(0, attempt - 1)
        }

        private func pause(seconds: Int) async {
            guard seconds > 0 else { return }
            do {
                try await Task.sleep(for: .seconds(seconds))
            } catch {
                return
            }
        }

        private func error(
            method: String,
            path: String,
            response: (data: Data, status: Int, headers: [String: String])
        ) -> GitHubClient.Error {
            .http(
                method: method,
                path: path,
                status: response.status,
                response: String(decoding: response.data.prefix(2_000), as: UTF8.self)
            )
        }

        private func decode<T: Decodable>(
            _ type: T.Type,
            from data: Data,
            path: String
        ) throws(Error) -> T {
            do {
                return try JSONDecoder().decode(type, from: data)
            } catch {
                throw Error.decoding(path: path, message: String(describing: error))
            }
        }

        /// Encodes a request body whose value is a string dictionary — a
        /// shape `JSONEncoder` encodes totally, so a failure here is a
        /// programming error, not a runtime condition.
        private func encode(_ body: [String: String]) -> Data {
            do {
                return try JSONEncoder().encode(body)
            } catch {
                preconditionFailure("string dictionary failed to encode: \(error)")
            }
        }

        private func encodeObject(_ body: Any) -> Data {
            do {
                return try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
            } catch {
                preconditionFailure("JSON request body failed to encode: \(error)")
            }
        }

        private func isGovernedSurface(path: String) -> Bool {
            if path.hasPrefix(".github/ISSUE_TEMPLATE/") {
                return true
            }
            if path.hasPrefix(".github/workflows/") {
                return path.hasSuffix(".yml") || path.hasSuffix(".yaml")
            }
            if path.hasPrefix(".github/actions/") {
                return path.hasSuffix("/action.yml") || path.hasSuffix("/action.yaml")
            }
            return false
        }

        private struct Content: Decodable {
            let type: String
            let path: String
            let encoding: String?
            let content: String?
        }

        private struct WaveRepository: Decodable {
            let id: Int64
            let visibility: String
            let archived: Bool
            let disabled: Bool
            let defaultBranch: String

            enum CodingKeys: String, CodingKey {
                case id
                case visibility
                case archived
                case disabled
                case defaultBranch = "default_branch"
            }
        }

        private struct WaveOrganization: Decodable {
            let publicRepos: Int

            enum CodingKeys: String, CodingKey {
                case publicRepos = "public_repos"
            }
        }

        private struct WaveRateLimit: Decodable {
            let resources: Resources

            struct Resources: Decodable {
                let core: Core

                struct Core: Decodable {
                    let remaining: Int
                    let reset: Int
                }
            }
        }

        private struct WaveReference: Decodable {
            let object: WaveSHA
        }

        private struct WaveContent: Decodable {
            let sha: String
            let type: String
            let encoding: String
            let content: String
        }

        private struct WaveRuleset: Decodable {
            let id: Int64
            let name: String
        }

        private struct WaveSHA: Decodable {
            let sha: String
        }

        private struct WaveCommit: Decodable {
            let tree: WaveSHA
        }

        private struct RemoteIssue: Decodable {
            let body: String?
            let htmlURL: String
            let state: String
            let stateReason: String?

            enum CodingKeys: String, CodingKey {
                case body
                case htmlURL = "html_url"
                case state
                case stateReason = "state_reason"
            }
        }

        private struct PrivateVulnerabilityReporting: Decodable {
            let enabled: Bool
        }
    }
}
