import Institute_Repository_Policy
import Foundation

extension RepositoryPolicy {
    public struct Scope: Equatable, Sendable {
        public let organization: String?
        public let repository: String?

        public init(
            organization: String?,
            repository: String?
        ) throws(RepositoryPolicy.ConfigurationError) {
            let organization = organization.flatMap { $0.isEmpty ? nil : $0 }
            let repository = repository.flatMap { $0.isEmpty ? nil : $0 }
            guard (organization == nil) != (repository == nil) else {
                throw ConfigurationError(
                    "exactly one of --organization or --repository is required"
                )
            }
            let owner = repository.map { String($0.prefix { $0 != "/" }) } ?? organization!
            guard owner != "tenthijeboonkkamp" else {
                throw ConfigurationError("owner tenthijeboonkkamp is outside Institute scope")
            }
            if let repository,
                repository.split(separator: "/", omittingEmptySubsequences: false).count != 2
            {
                throw ConfigurationError("--repository must use owner/name form")
            }
            self.organization = organization
            self.repository = repository
        }
    }

    public struct Configuration: Sendable {
        public let scope: Scope
        public let dryRun: Bool
        public let journal: URL
        public let receipt: URL

        public init(scope: Scope, dryRun: Bool, journal: URL, receipt: URL) {
            self.scope = scope
            self.dryRun = dryRun
            self.journal = journal
            self.receipt = receipt
        }
    }

    public struct Receipt: Codable, Equatable, Sendable {
        public let scope: String
        public let dryRun: Bool
        public let examined: Int
        public let eligible: Int
        public let excluded: [String: Int]
        public let converged: Int
        public let enabled: Int
        public let wouldEnable: Int
        public let verifiedRepositories: [String]
    }

    public struct ConfigurationError: Swift.Error, CustomStringConvertible, Sendable {
        public let description: String

        public init(_ description: String) {
            self.description = description
        }
    }

    /// Every way a policy sweep refuses: a client operation failed, or a
    /// local configuration or filesystem precondition did.
    public enum Error: Swift.Error, CustomStringConvertible, Sendable {
        case client(GitHubClient.Error)
        case configuration(ConfigurationError)

        public var description: String {
            switch self {
            case .client(let error): return String(describing: error)
            case .configuration(let error): return error.description
            }
        }
    }

    /// Lifts one client operation's refusal into the sweep-level error.
    private static func calling<T>(
        _ body: () async throws(GitHubClient.Error) -> T
    ) async throws(RepositoryPolicy.Error) -> T {
        do {
            return try await body()
        } catch {
            throw .client(error)
        }
    }

    public static func run(
        client: GitHubClient,
        configuration: Configuration
    ) async throws(RepositoryPolicy.Error) -> Receipt {
        let repositories: [Repository]
        let scopeDescription: String
        if let fullName = configuration.scope.repository {
            repositories = [
                try await calling { () async throws(GitHubClient.Error) in
                    try await client.repository(fullName)
                }
            ]
            scopeDescription = fullName
        } else {
            let organization = configuration.scope.organization!
            repositories = try await calling { () async throws(GitHubClient.Error) in
                try await client.repositories(organization: organization)
            }
            scopeDescription = organization
        }

        let journal = try Journal(url: configuration.journal)
        var excluded = [String: Int]()
        var eligible = 0
        var converged = 0
        var enabled = 0
        var wouldEnable = 0
        var verified = [String]()

        for repository in repositories.sorted(by: { $0.fullName < $1.fullName }) {
            if let reason = staticExclusion(of: repository) {
                excluded[reason.rawValue, default: 0] += 1
                continue
            }

            let manifestKind = try await calling { () async throws(GitHubClient.Error) in
                try await client.rootManifestKind(repository.fullName)
            }
            guard manifestKind == "file" else {
                let reason: Exclusion =
                    manifestKind == nil ? .missingRootManifest : .rootManifestNotFile
                excluded[reason.rawValue, default: 0] += 1
                continue
            }

            eligible += 1
            let state = try await calling { () async throws(GitHubClient.Error) in
                try await client.vulnerabilityReporting(repository.fullName)
            }
            switch decision(
                for: repository,
                manifestKind: manifestKind,
                vulnerabilityReporting: state
            ) {
            case .excluded(let reason):
                excluded[reason.rawValue, default: 0] += 1

            case .converged:
                converged += 1
                verified.append(repository.fullName)
                try journal.append(repository: repository.fullName, phase: "verified-existing")

            case .enable:
                if configuration.dryRun {
                    wouldEnable += 1
                    try journal.append(repository: repository.fullName, phase: "would-enable")
                    continue
                }
                try journal.append(repository: repository.fullName, phase: "prepared")
                try await calling { () async throws(GitHubClient.Error) in
                    try await client.enableVulnerabilityReporting(repository.fullName)
                }
                try journal.append(repository: repository.fullName, phase: "accepted")
                try await verifyEnabled(client: client, repository: repository.fullName)
                try journal.append(repository: repository.fullName, phase: "verified-enabled")
                enabled += 1
                verified.append(repository.fullName)
            }
        }

        // An explicitly named repository that turns out excluded (not
        // public, archived, a fork, empty, or missing a root manifest) is a
        // legitimate GitHub-side fact, not an operator mistake — a typo or
        // out-of-scope owner already fails earlier, in `Scope.init` or the
        // repository fetch above. Report the divergence through `excluded`
        // on the receipt below rather than failing the whole dispatch
        // (swift-institute/.github#160).

        let receipt = Receipt(
            scope: scopeDescription,
            dryRun: configuration.dryRun,
            examined: repositories.count,
            eligible: eligible,
            excluded: excluded,
            converged: converged,
            enabled: enabled,
            wouldEnable: wouldEnable,
            verifiedRepositories: verified.sorted()
        )
        try write(receipt, to: configuration.receipt)
        return receipt
    }

    public static func validateSurfaces(
        client: GitHubClient,
        scope: Scope,
        policy: SurfacePolicy
    ) async throws(RepositoryPolicy.Error) -> SurfaceSweepReport {
        let repositories: [Repository]
        if let fullName = scope.repository {
            repositories = [
                try await calling { () async throws(GitHubClient.Error) in
                    try await client.repository(fullName)
                }
            ]
        } else {
            repositories = try await calling { () async throws(GitHubClient.Error) in
                try await client.repositories(organization: scope.organization!)
            }
        }

        var reports = [SurfaceReport]()
        for repository in repositories.sorted(by: { $0.fullName < $1.fullName }) {
            guard staticExclusion(of: repository) == nil else { continue }
            let manifestKind = try await calling { () async throws(GitHubClient.Error) in
                try await client.rootManifestKind(repository.fullName)
            }
            guard manifestKind == "file" else { continue }
            let repositoryClass =
                policy.actionGrants
                .first { $0.repository == repository.fullName }?
                .repositoryClass ?? .package
            let files = try await calling { () async throws(GitHubClient.Error) in
                try await client.surfaceFiles(repository.fullName)
            }
            let report: SurfaceReport
            do throws(ConfigurationError) {
                report = try validateSurface(
                    repository: repository.fullName,
                    repositoryClass: repositoryClass,
                    files: files,
                    policy: policy
                )
            } catch {
                throw .configuration(error)
            }
            reports.append(report)
        }
        return SurfaceSweepReport(reports: reports)
    }

    private static func verifyEnabled(
        client: GitHubClient,
        repository: String
    ) async throws(RepositoryPolicy.Error) {
        for attempt in 1...6 {
            let state = try await calling { () async throws(GitHubClient.Error) in
                try await client.vulnerabilityReporting(repository)
            }
            if state == .enabled { return }
            guard attempt < 6 else {
                throw .configuration(
                    ConfigurationError("\(repository): PVR was not enabled after accepted PUT")
                )
            }
            do {
                try await Task<Never, Never>.sleep(for: .seconds(1))
            } catch {
                throw .configuration(ConfigurationError("\(repository): retry wait was cancelled"))
            }
        }
    }

    private static func write(
        _ receipt: Receipt,
        to url: URL
    ) throws(RepositoryPolicy.Error) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            var data = try encoder.encode(receipt)
            data.append(0x0A)
            try data.write(to: url, options: .atomic)
        } catch {
            throw .configuration(
                ConfigurationError("could not write receipt to \(url.path): \(error)")
            )
        }
    }

    private final class Journal {
        private let handle: FileHandle

        init(url: URL) throws(RepositoryPolicy.Error) {
            let manager = FileManager.default
            if !manager.fileExists(atPath: url.path) {
                guard manager.createFile(atPath: url.path, contents: nil) else {
                    throw .configuration(
                        ConfigurationError("could not create journal at \(url.path)")
                    )
                }
            }
            do {
                handle = try FileHandle(forWritingTo: url)
                try handle.seekToEnd()
            } catch {
                throw .configuration(
                    ConfigurationError("could not open journal at \(url.path): \(error)")
                )
            }
        }

        deinit {
            do {
                try handle.close()
            } catch {
                // A journal handle that cannot close during teardown has
                // nothing left to report to; the records already written
                // were synchronized per append.
            }
        }

        func append(repository: String, phase: String) throws(RepositoryPolicy.Error) {
            let record = JournalRecord(repository: repository, phase: phase)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            do {
                var data = try encoder.encode(record)
                data.append(0x0A)
                try handle.write(contentsOf: data)
                try handle.synchronize()
            } catch {
                throw .configuration(
                    ConfigurationError("could not append to the journal: \(error)")
                )
            }
        }
    }

    private struct JournalRecord: Codable {
        let repository: String
        let phase: String
    }
}
