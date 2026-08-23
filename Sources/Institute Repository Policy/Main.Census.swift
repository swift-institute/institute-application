import Institute_Repository_Policy
import Foundation

extension Institute.Application.RepositoryPolicyCLI {
    /// `repository-policy census --repo <name>=<root>=<headSha> ... --output <csv>`
    ///
    /// Regenerates the FT1 census from checked-out trees at the given heads
    /// (F1; swift-institute/.github#363). Deterministic sorted traversal;
    /// parity with the FT1 artifact is order-normalized.
    static func census(_ arguments: [String]) throws(Error) {
        var repos: [Repository.Policy.Census.Generator.Repo] = []
        var output: String?
        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--repo":
                guard let value = iterator.next() else {
                    throw .configuration(
                        RepositoryPolicy.ConfigurationError("--repo needs <name>=<root>=<headSha>")
                    )
                }
                let parts = value.split(separator: "=", maxSplits: 2).map(String.init)
                guard parts.count == 3 else {
                    throw .configuration(
                        RepositoryPolicy.ConfigurationError("--repo needs <name>=<root>=<headSha>")
                    )
                }
                repos.append(.init(name: parts[0], root: parts[1], headSha: parts[2]))

            case "--output":
                output = iterator.next()

            default:
                throw .configuration(
                    RepositoryPolicy.ConfigurationError("unknown census argument \(argument)")
                )
            }
        }
        guard let output, !repos.isEmpty else {
            throw .configuration(
                RepositoryPolicy.ConfigurationError("census requires --repo … and --output")
            )
        }
        let census: Repository.Policy.Census
        do throws(Repository.Policy.Census.Generator.Error) {
            census = try Repository.Policy.Census.Generator(repos: repos).run()
        } catch {
            throw .census(error)
        }
        do {
            try Data(census.normalized.csv.utf8)
                .write(to: URL(fileURLWithPath: output))
        } catch {
            throw .io("could not write census to \(output): \(error)")
        }
        var byKind: [String: Int] = [:]
        for row in census.rows {
            byKind[row.coordinateKind.rawValue, default: 0] += 1
        }
        let summary = byKind.sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        print("institute repository: census rows=\(census.rows.count) \(summary)")
    }

    /// `repository-policy capability-records --output <json>` — emits the
    /// FT1-frozen D-01…D-12 capability records.
    static func capabilityRecords(_ arguments: [String]) throws(Error) {
        guard arguments.count == 2, arguments[0] == "--output" else {
            throw .configuration(
                RepositoryPolicy.ConfigurationError("capability-records requires --output <path>")
            )
        }
        let records: Data
        do throws(RepositoryPolicy.ConfigurationError) {
            records = try Repository.Policy.Capability.recordsJSON()
        } catch {
            throw .configuration(error)
        }
        do {
            try records.write(to: URL(fileURLWithPath: arguments[1]))
        } catch {
            throw .io("could not write capability records to \(arguments[1]): \(error)")
        }
        print(
            "institute repository: capability-records count=\(Repository.Policy.Capability.records.count)"
        )
    }
}
