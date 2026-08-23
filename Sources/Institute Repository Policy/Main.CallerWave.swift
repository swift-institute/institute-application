import Institute_Repository_Policy
import Foundation

extension Institute.Application.RepositoryPolicyCLI {
    static func callerWave(_ arguments: [String]) async throws(Error) {
        guard let operation = arguments.first else {
            throw waveConfiguration(
                "caller-wave requires census, capacity, attest, preflight, apply, close, "
                    + "recensus, or restore"
            )
        }
        let values = try callerWaveValues(Array(arguments.dropFirst()))
        if operation == "attest" {
            return try attestCallerWave(values)
        }
        let client = try callerWaveClient()
        switch operation {
        case "census":
            try await censusCallerWave(values, client: client)

        case "capacity":
            try await capacityCallerWave(values, client: client)

        case "preflight":
            try await preflightCallerWave(values, client: client)

        case "apply":
            try await applyCallerWave(values, client: client)

        case "close":
            try await closeCallerWave(values, client: client)

        case "recensus":
            try await recensusCallerWave(values, client: client)

        case "restore":
            try await restoreCallerWave(values, client: client)

        default:
            throw waveConfiguration(
                "caller-wave operation must be census, capacity, attest, preflight, apply, "
                    + "close, recensus, or restore"
            )
        }
    }

    private static func attestCallerWave(_ values: [String: String]) throws(Error) {
        let required = [
            "--organization", "--app-client-id", "--app-slug", "--installation-id",
            "--repositories", "--permissions", "--run-id", "--output",
        ]
        try require(values, keys: required, operation: "attest")
        guard let installationID = Int64(values["--installation-id"]!), installationID > 0 else {
            throw waveConfiguration("caller-wave --installation-id must be a positive integer")
        }
        guard let runID = Int64(values["--run-id"]!), runID > 0 else {
            throw waveConfiguration("caller-wave --run-id must be a positive integer")
        }
        let organization = values["--organization"]!
        let appClientID = values["--app-client-id"]!
        let appSlug = values["--app-slug"]!
        guard !organization.isEmpty, !appClientID.isEmpty, !appSlug.isEmpty else {
            throw waveConfiguration("caller-wave attest identity values must be nonempty")
        }
        let repositories = values["--repositories"]!.split(separator: ",").map(String.init)
        guard !repositories.isEmpty else {
            throw waveConfiguration("caller-wave attest --repositories must be nonempty")
        }
        var permissions: [String: String] = [:]
        for entry in values["--permissions"]!.split(separator: ",") {
            let pair = entry.split(separator: "=", omittingEmptySubsequences: false)
            guard pair.count == 2, !pair[0].isEmpty, !pair[1].isEmpty,
                permissions.updateValue(String(pair[1]), forKey: String(pair[0])) == nil
            else {
                throw waveConfiguration(
                    "caller-wave attest --permissions must be unique permission=grant pairs"
                )
            }
        }
        guard !permissions.isEmpty else {
            throw waveConfiguration("caller-wave attest --permissions must be nonempty")
        }
        let attestation = Repository.Policy.Caller.Wave.Attestation(
            appClientID: appClientID,
            appSlug: appSlug,
            installationID: installationID,
            organization: organization,
            repositories: repositories,
            permissions: permissions,
            runID: runID,
            issuedAt: ISO8601DateFormatter().string(from: Date())
        )
        try encode(attestation, to: URL(filePath: values["--output"]!))
        print(
            "institute repository: caller-wave attested \(organization) "
                + "repositories=\(repositories.count) installation=\(installationID)"
        )
    }

    private static func capacityCallerWave(
        _ values: [String: String],
        client: RepositoryPolicy.GitHubClient
    ) async throws(Error) {
        // Exactly one requirement source: an explicit fixed budget
        // (census/recensus enumeration), or a subject count the Swift
        // owner prices itself — the host never carries the formula.
        let required: Int
        switch (values["--required"], values["--subjects"]) {
        case (let requiredValue?, nil):
            guard values.count == 2, let value = Int(requiredValue), value > 0 else {
                throw waveConfiguration(
                    "caller-wave capacity requires --required <positive integer> --output <path>"
                )
            }
            required = value

        case (nil, let subjectsValue?):
            guard values.count == 2, let subjects = Int(subjectsValue), subjects > 0 else {
                throw waveConfiguration(
                    "caller-wave capacity requires --subjects <positive integer> --output <path>"
                )
            }
            required = Repository.Policy.Caller.Wave.Capacity.requirement(subjects: subjects)

        default:
            throw waveConfiguration(
                "caller-wave capacity requires exactly one of --required or --subjects"
            )
        }
        guard let output = values["--output"] else {
            throw waveConfiguration("caller-wave capacity requires --output <path>")
        }
        let capacity: Repository.Policy.Caller.Wave.Capacity
        do throws(RepositoryPolicy.GitHubClient.Error) {
            capacity = try await client.capacity(requiredRequests: required)
        } catch {
            throw .client(error)
        }
        try encode(capacity, to: URL(filePath: output))
        guard capacity.accepted else {
            throw .wave(
                .verification(
                    "GitHub API capacity has \(capacity.remaining) requests remaining; "
                        + "\(capacity.required) are required"
                )
            )
        }
        print(
            "institute repository: caller-wave capacity accepted remaining=\(capacity.remaining) "
                + "required=\(capacity.required) reset=\(capacity.resetAt)"
        )
    }

    private static func censusCallerWave(
        _ values: [String: String],
        client: RepositoryPolicy.GitHubClient
    ) async throws(Error) {
        guard values.count == 2,
            let fleetPath = values["--fleet"],
            let output = values["--output"]
        else {
            throw waveConfiguration("caller-wave census requires --fleet <policy> --output <path>")
        }
        let fleet = try fleet(at: fleetPath)
        let population: Repository.Policy.Caller.Wave.Population
        do throws(Repository.Policy.Caller.Wave.Error) {
            population = try await Repository.Policy.Caller.Wave.enumerate(
                client: client,
                fleet: fleet
            )
        } catch {
            throw .wave(error)
        }
        try encode(population, to: URL(filePath: output))
        print(
            "institute repository: caller-wave census examined=\(population.examined) "
                + "eligible=\(population.subjects.count) "
                + "digest=\(population.commitment.stateDigest)"
        )
    }

    private static func preflightCallerWave(
        _ values: [String: String],
        client: RepositoryPolicy.GitHubClient
    ) async throws(Error) {
        let required = [
            "--repository", "--population", "--caller", "--policy", "--integration-id",
            "--policy-digest", "--policy-source", "--attestation", "--recovery", "--receipt",
        ]
        try require(values, keys: required, operation: "preflight")
        let attestation:
            (
                attestation: Repository.Policy.Caller.Wave.Attestation,
                digest: String
            )
        do throws(Repository.Policy.Caller.Wave.Error) {
            attestation = try Repository.Policy.Caller.Wave.Attestation.read(
                at: values["--attestation"]!
            )
        } catch {
            throw .wave(error)
        }
        let population: Repository.Policy.Caller.Wave.Population = try decode(
            at: values["--population"]!,
            label: "caller-wave population"
        )
        do throws(Repository.Policy.Caller.Wave.Error) {
            try population.validate()
        } catch {
            throw .wave(error)
        }
        let repository = values["--repository"]!
        guard let subject = population.subjects.first(where: { $0.repository == repository }),
            population.subjects.filter({ $0.repository == repository }).count == 1
        else {
            throw waveConfiguration(
                "\(repository): not exactly one subject in committed population"
            )
        }
        let request = try callerWaveRequest(
            subject: subject,
            population: population.commitment,
            values: values
        )
        let result:
            (
                recovery: Repository.Policy.Caller.Wave.Recovery,
                receipt: Repository.Policy.Caller.Wave.Preflight
            )
        do throws(Repository.Policy.Caller.Wave.Error) {
            result = try await Repository.Policy.Caller.Wave.preflight(
                client: client,
                request: request,
                attestation: attestation.attestation,
                attestationDigest: attestation.digest
            )
        } catch {
            throw .wave(error)
        }
        try encode(result.recovery, to: URL(filePath: values["--recovery"]!))
        try encode(result.receipt, to: URL(filePath: values["--receipt"]!))
        print(
            "institute repository: caller-wave preflight accepted \(repository) "
                + "recovery=\(result.receipt.recoveryDigest)"
        )
    }

    private static func applyCallerWave(
        _ values: [String: String],
        client: RepositoryPolicy.GitHubClient
    ) async throws(Error) {
        let required = ["--recovery", "--caller", "--events", "--receipt"]
        try require(values, keys: required, operation: "apply")
        let recovery: Repository.Policy.Caller.Wave.Recovery = try decode(
            at: values["--recovery"]!,
            label: "caller-wave recovery"
        )
        let caller = try data(at: values["--caller"]!, label: "terminal caller")
        let request = Repository.Policy.Caller.Wave.Request(
            repository: recovery.repository,
            expectedRepositoryID: recovery.repositoryID,
            expectedHead: recovery.rollbackHead,
            expectedManifest: recovery.manifest,
            expectedBlob: recovery.caller.blob,
            caller: caller,
            canonicalRuleset: recovery.canonicalRuleset,
            integrationID: recovery.integrationID,
            population: recovery.population,
            policyDigest: recovery.policyDigest,
            policySource: recovery.policySource,
            commitMessage: terminalCallerCommitMessage
        )
        let eventsURL = URL(filePath: values["--events"]!)
        let receipt: Repository.Policy.Caller.Wave.Receipt
        do throws(Repository.Policy.Caller.Wave.Error) {
            receipt = try await Repository.Policy.Caller.Wave.run(
                client: client,
                request: request,
                recovery: recovery,
                record: { try append($0, to: eventsURL) }
            )
        } catch {
            throw .wave(error)
        }
        try encode(receipt, to: URL(filePath: values["--receipt"]!))
        print(
            "institute repository: caller-wave \(receipt.changed ? "applied" : "converged") "
                + "\(receipt.repository) head=\(receipt.newHead) blob=\(receipt.newBlob) "
                + "bypass-closed=\(receipt.bypassClosed)"
        )
    }

    private static func closeCallerWave(
        _ values: [String: String],
        client: RepositoryPolicy.GitHubClient
    ) async throws(Error) {
        let required = ["--recovery", "--caller", "--output"]
        try require(values, keys: required, operation: "close")
        let recovery: Repository.Policy.Caller.Wave.Recovery = try decode(
            at: values["--recovery"]!,
            label: "caller-wave recovery"
        )
        let caller = try data(at: values["--caller"]!, label: "terminal caller")
        let closure: Repository.Policy.Caller.Wave.Closure
        do throws(Repository.Policy.Caller.Wave.Error) {
            closure = try await Repository.Policy.Caller.Wave.close(
                client: client,
                recovery: recovery,
                caller: caller
            )
        } catch {
            throw .wave(error)
        }
        try encode(closure, to: URL(filePath: values["--output"]!))
        guard closure.accepted else {
            throw .wave(.verification("\(closure.repository): terminal closure was not accepted"))
        }
        print("institute repository: caller-wave closure accepted \(closure.repository)")
    }

    private static func recensusCallerWave(
        _ values: [String: String],
        client: RepositoryPolicy.GitHubClient
    ) async throws(Error) {
        let required = [
            "--fleet", "--original", "--caller", "--receipts", "--events", "--closures",
            "--policy-digest", "--policy-source", "--output",
        ]
        try require(values, keys: required, operation: "recensus")
        let original: Repository.Policy.Caller.Wave.Population = try decode(
            at: values["--original"]!,
            label: "original caller-wave population"
        )
        let fleetPolicy = try fleet(at: values["--fleet"]!)
        let current: Repository.Policy.Caller.Wave.Population
        do throws(Repository.Policy.Caller.Wave.Error) {
            current = try await Repository.Policy.Caller.Wave.enumerate(
                client: client,
                fleet: fleetPolicy
            )
        } catch {
            throw .wave(error)
        }
        let caller = try data(at: values["--caller"]!, label: "terminal caller")
        let receipts: [Repository.Policy.Caller.Wave.Receipt] = try decodeDirectory(
            at: values["--receipts"]!,
            label: "caller-wave receipts"
        )
        let closures: [Repository.Policy.Caller.Wave.Closure] = try decodeDirectory(
            at: values["--closures"]!,
            label: "caller-wave closures"
        )
        let events: [Repository.Policy.Caller.Wave.Event] = try decodeLinesDirectory(
            at: values["--events"]!,
            label: "caller-wave events"
        )
        let recensus: Repository.Policy.Caller.Wave.Recensus
        do throws(Repository.Policy.Caller.Wave.Error) {
            recensus = try Repository.Policy.Caller.Wave.recensus(
                original: original,
                current: current,
                evidence: .init(
                    caller: caller,
                    receipts: receipts,
                    events: events,
                    closures: closures,
                    policyDigest: values["--policy-digest"]!,
                    policySource: values["--policy-source"]!
                )
            )
        } catch {
            throw .wave(error)
        }
        try encode(recensus, to: URL(filePath: values["--output"]!))
        guard recensus.accepted else {
            let mismatches = recensus.observations.filter { !$0.matches }.map(\.repository)
            throw .wave(
                .verification(
                    "terminal recensus refused \(mismatches.count) subjects: "
                        + mismatches.joined(separator: ", ")
                )
            )
        }
        print(
            "institute repository: caller-wave recensus accepted "
                + "examined=\(recensus.examined) eligible=\(recensus.observations.count) "
                + "population=\(recensus.originalPopulation.subjectDigest)"
        )
    }

    private static func restoreCallerWave(
        _ values: [String: String],
        client: RepositoryPolicy.GitHubClient
    ) async throws(Error) {
        guard values.count == 1, let path = values["--recovery"] else {
            throw waveConfiguration("caller-wave restore requires only --recovery <path>")
        }
        let recovery: Repository.Policy.Caller.Wave.Recovery = try decode(
            at: path,
            label: "caller-wave recovery"
        )
        guard let snapshot = recovery.priorRuleset else {
            print("institute repository: caller-wave recovery has no prior ruleset")
            return
        }
        do throws(Repository.Policy.Caller.Wave.Error) {
            try await Repository.Policy.Caller.Wave.restore(client: client, snapshot: snapshot)
        } catch {
            throw .wave(error)
        }
        print("institute repository: caller-wave restored \(recovery.repository)")
    }

    private static func callerWaveRequest(
        subject: Repository.Policy.Caller.Wave.Subject,
        population: Repository.Policy.Caller.Wave.Commitment,
        values: [String: String]
    ) throws(Error) -> Repository.Policy.Caller.Wave.Request {
        guard let integrationID = Int64(values["--integration-id"]!), integrationID > 0 else {
            throw waveConfiguration("caller-wave --integration-id must be a positive integer")
        }
        let policyDigest = values["--policy-digest"]!
        let policySource = values["--policy-source"]!
        guard policyDigest.count == 64, policySource.count == 40 else {
            throw waveConfiguration("caller-wave policy digest or source is not exact")
        }
        let canonicalRuleset: Data
        do throws(RepositoryPolicy.ConfigurationError) {
            canonicalRuleset = try RepositoryPolicy.Ruleset.protectedMainPayload(
                from: URL(filePath: values["--policy"]!)
            )
        } catch {
            throw .configuration(error)
        }
        return .init(
            repository: subject.repository,
            expectedRepositoryID: subject.repositoryID,
            expectedHead: subject.head,
            expectedManifest: subject.manifest,
            expectedBlob: subject.caller.blob,
            caller: try data(at: values["--caller"]!, label: "terminal caller"),
            canonicalRuleset: canonicalRuleset,
            integrationID: integrationID,
            population: population,
            policyDigest: policyDigest,
            policySource: policySource,
            commitMessage: terminalCallerCommitMessage
        )
    }

    private static var terminalCallerCommitMessage: String {
        """
        Adopt the terminal package CI caller [skip ci]

        Refs swift-institute/institute-continuous-integration#35
        """
    }

    static func fleet(at path: String) throws(Error) -> RepositoryPolicy.Fleet {
        do {
            return try RepositoryPolicy.Fleet.read(at: path)
        } catch {
            throw .io("could not read caller-wave fleet policy at \(path): \(error)")
        }
    }

    static func require(
        _ values: [String: String],
        keys: [String],
        operation: String
    ) throws(Error) {
        guard values.count == keys.count, keys.allSatisfy({ values[$0] != nil }) else {
            throw waveConfiguration(
                "caller-wave \(operation) requires \(keys.joined(separator: ", "))"
            )
        }
    }

    static func waveConfiguration(_ message: String) -> Error {
        .configuration(RepositoryPolicy.ConfigurationError(message))
    }

    static func callerWaveClient() throws(Error) -> RepositoryPolicy.GitHubClient {
        guard let token = ProcessInfo.processInfo.environment["GH_TOKEN"], !token.isEmpty else {
            throw waveConfiguration("GH_TOKEN is required")
        }
        let api = ProcessInfo.processInfo.environment["GITHUB_API_URL"] ?? "https://api.github.com"
        guard let baseURL = URL(string: api) else {
            throw waveConfiguration("GITHUB_API_URL is invalid")
        }
        return RepositoryPolicy.GitHubClient(token: token, baseURL: baseURL)
    }

    static func callerWaveValues(_ arguments: [String]) throws(Error) -> [String: String] {
        guard arguments.count.isMultiple(of: 2) else {
            throw waveConfiguration("caller-wave arguments require values")
        }
        var values: [String: String] = [:]
        var iterator = arguments.makeIterator()
        while let key = iterator.next(), let value = iterator.next() {
            guard key.hasPrefix("--"), values.updateValue(value, forKey: key) == nil else {
                throw waveConfiguration("caller-wave argument is invalid or repeated: \(key)")
            }
        }
        return values
    }

    static func data(at path: String, label: String) throws(Error) -> Data {
        do {
            return try Data(contentsOf: URL(filePath: path))
        } catch {
            throw .io("could not read \(label) at \(path): \(error)")
        }
    }

    static func decode<T: Decodable>(at path: String, label: String) throws(Error) -> T {
        do {
            return try JSONDecoder().decode(T.self, from: Data(contentsOf: URL(filePath: path)))
        } catch {
            throw .io("could not decode \(label) at \(path): \(error)")
        }
    }

    static func decodeDirectory<T: Decodable>(
        at path: String,
        label: String
    ) throws(Error) -> [T] {
        let urls = try evidenceURLs(at: path, label: label)
        var result: [T] = []
        for url in urls {
            result.append(try decode(at: url.path, label: label))
        }
        return result
    }

    static func decodeLinesDirectory<T: Decodable>(
        at path: String,
        label: String
    ) throws(Error) -> [T] {
        let decoder = JSONDecoder()
        var result: [T] = []
        for url in try evidenceURLs(at: path, label: label) {
            let bytes = try data(at: url.path, label: label)
            for line in bytes.split(separator: 0x0A) {
                do {
                    result.append(try decoder.decode(T.self, from: Data(line)))
                } catch {
                    throw Error.io("could not decode \(label) at \(url.path): \(error)")
                }
            }
        }
        return result
    }

    private static func evidenceURLs(at path: String, label: String) throws(Error) -> [URL] {
        do {
            let urls = try FileManager.default.contentsOfDirectory(
                at: URL(filePath: path),
                includingPropertiesForKeys: [.isRegularFileKey]
            ).filter { $0.pathExtension == "json" || $0.pathExtension == "jsonl" }
                .sorted(by: { $0.path < $1.path })
            guard !urls.isEmpty else { throw Error.io("\(label) directory is empty: \(path)") }
            return urls
        } catch let error as Error {
            throw error
        } catch {
            throw .io("could not enumerate \(label) at \(path): \(error)")
        }
    }

    static func encode<T: Encodable>(_ value: T, to url: URL) throws(Error) {
        // Evidence files must carry the exact canonical bytes the library
        // digests, so recorded digests equal an independent file checksum.
        let data: Data
        do throws(Repository.Policy.Caller.Wave.Error) {
            data = try Repository.Policy.Caller.Wave.evidenceData(value)
        } catch {
            throw .wave(error)
        }
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            throw .io("could not encode \(url.path): \(error)")
        }
    }

    static func append<T: Encodable>(_ value: T, to url: URL) throws(Error) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            var data = try encoder.encode(value)
            data.append(0x0A)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if !FileManager.default.fileExists(atPath: url.path) {
                try Data().write(to: url, options: .atomic)
            }
            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            try handle.synchronize()
            try handle.close()
        } catch {
            throw .io("could not append \(url.path): \(error)")
        }
    }
}
