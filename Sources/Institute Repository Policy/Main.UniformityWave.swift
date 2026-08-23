import Institute_Repository_Policy
import Foundation

extension Institute.Application.RepositoryPolicyCLI {
    static func uniformityWave(_ arguments: [String]) async throws(Error) {
        guard let operation = arguments.first else {
            throw waveConfiguration(
                "uniformity-wave requires payload, census, capacity, attest, preflight, apply, "
                    + "close, recensus, or restore"
            )
        }
        let values = try callerWaveValues(Array(arguments.dropFirst()))
        if operation == "payload" {
            return try payloadUniformityWave(values)
        }
        if operation == "attest" {
            return try attestUniformityWave(values)
        }
        let client = try callerWaveClient()
        switch operation {
        case "census":
            try await censusUniformityWave(values, client: client)

        case "capacity":
            try await capacityUniformityWave(values, client: client)

        case "preflight":
            try await preflightUniformityWave(values, client: client)

        case "apply":
            try await applyUniformityWave(values, client: client)

        case "close":
            try await closeUniformityWave(values, client: client)

        case "recensus":
            try await recensusUniformityWave(values, client: client)

        case "restore":
            try await restoreUniformityWave(values, client: client)

        default:
            throw waveConfiguration(
                "uniformity-wave operation must be payload, census, capacity, attest, "
                    + "preflight, apply, close, recensus, or restore"
            )
        }
    }

    /// Writes the embedded ratified shape policy bytes, digest-verified,
    /// so every host phase consumes one canonical file whose checksum an
    /// independent verifier can compare against the ratified digest.
    private static func payloadUniformityWave(_ values: [String: String]) throws(Error) {
        guard values.count == 1, let output = values["--output"] else {
            throw waveConfiguration("uniformity-wave payload requires only --output <path>")
        }
        let payload: Data
        do throws(Repository.Policy.Uniformity.Wave.Error) {
            payload = try Repository.Policy.Uniformity.Wave.Payload.canonical()
        } catch {
            throw .wave(error)
        }
        let url = URL(filePath: output)
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try payload.write(to: url, options: .atomic)
        } catch {
            throw .io("could not write \(url.path): \(error)")
        }
        print(
            "institute repository: uniformity-wave payload "
                + "digest=\(Repository.Policy.Uniformity.Wave.Payload.digest)"
        )
    }

    private static func attestUniformityWave(_ values: [String: String]) throws(Error) {
        let required = [
            "--organization", "--app-client-id", "--app-slug", "--installation-id",
            "--repositories", "--permissions", "--run-id", "--output",
        ]
        try require(values, keys: required, operation: "attest")
        guard let installationID = Int64(values["--installation-id"]!), installationID > 0 else {
            throw waveConfiguration("uniformity-wave --installation-id must be a positive integer")
        }
        guard let runID = Int64(values["--run-id"]!), runID > 0 else {
            throw waveConfiguration("uniformity-wave --run-id must be a positive integer")
        }
        let organization = values["--organization"]!
        let appClientID = values["--app-client-id"]!
        let appSlug = values["--app-slug"]!
        guard !organization.isEmpty, !appClientID.isEmpty, !appSlug.isEmpty else {
            throw waveConfiguration("uniformity-wave attest identity values must be nonempty")
        }
        let repositories = values["--repositories"]!.split(separator: ",").map(String.init)
        guard !repositories.isEmpty else {
            throw waveConfiguration("uniformity-wave attest --repositories must be nonempty")
        }
        var permissions: [String: String] = [:]
        for entry in values["--permissions"]!.split(separator: ",") {
            let pair = entry.split(separator: "=", omittingEmptySubsequences: false)
            guard pair.count == 2, !pair[0].isEmpty, !pair[1].isEmpty,
                permissions.updateValue(String(pair[1]), forKey: String(pair[0])) == nil
            else {
                throw waveConfiguration(
                    "uniformity-wave attest --permissions must be unique permission=grant pairs"
                )
            }
        }
        guard !permissions.isEmpty else {
            throw waveConfiguration("uniformity-wave attest --permissions must be nonempty")
        }
        let attestation = Repository.Policy.Uniformity.Wave.Attestation(
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
            "institute repository: uniformity-wave attested \(organization) "
                + "repositories=\(repositories.count) installation=\(installationID)"
        )
    }

    private static func capacityUniformityWave(
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
                    "uniformity-wave capacity requires --required <positive integer> --output <path>"
                )
            }
            required = value

        case (nil, let subjectsValue?):
            guard values.count == 2, let subjects = Int(subjectsValue), subjects > 0 else {
                throw waveConfiguration(
                    "uniformity-wave capacity requires --subjects <positive integer> --output <path>"
                )
            }
            required = Repository.Policy.Uniformity.Wave.Capacity.requirement(subjects: subjects)

        default:
            throw waveConfiguration(
                "uniformity-wave capacity requires exactly one of --required or --subjects"
            )
        }
        guard let output = values["--output"] else {
            throw waveConfiguration("uniformity-wave capacity requires --output <path>")
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
            "institute repository: uniformity-wave capacity accepted remaining=\(capacity.remaining) "
                + "required=\(capacity.required) reset=\(capacity.resetAt)"
        )
    }

    private static func censusUniformityWave(
        _ values: [String: String],
        client: RepositoryPolicy.GitHubClient
    ) async throws(Error) {
        guard values.count == 2,
            let fleetPath = values["--fleet"],
            let output = values["--output"]
        else {
            throw waveConfiguration(
                "uniformity-wave census requires --fleet <policy> --output <path>"
            )
        }
        let fleet = try fleet(at: fleetPath)
        let population: Repository.Policy.Uniformity.Wave.Population
        do throws(Repository.Policy.Uniformity.Wave.Error) {
            population = try await Repository.Policy.Uniformity.Wave.enumerate(
                client: client,
                fleet: fleet
            )
        } catch {
            throw .wave(error)
        }
        try encode(population, to: URL(filePath: output))
        print(
            "institute repository: uniformity-wave census examined=\(population.examined) "
                + "eligible=\(population.subjects.count) "
                + "digest=\(population.commitment.stateDigest)"
        )
    }

    private static func preflightUniformityWave(
        _ values: [String: String],
        client: RepositoryPolicy.GitHubClient
    ) async throws(Error) {
        let required = [
            "--repository", "--population", "--payload", "--policy", "--integration-id",
            "--policy-digest", "--policy-source", "--attestation", "--recovery", "--receipt",
        ]
        try require(values, keys: required, operation: "preflight")
        let attestation:
            (
                attestation: Repository.Policy.Uniformity.Wave.Attestation,
                digest: String
            )
        do throws(Repository.Policy.Uniformity.Wave.Error) {
            attestation = try Repository.Policy.Uniformity.Wave.Attestation.read(
                at: values["--attestation"]!
            )
        } catch {
            throw .wave(error)
        }
        let population: Repository.Policy.Uniformity.Wave.Population = try decode(
            at: values["--population"]!,
            label: "uniformity-wave population"
        )
        do throws(Repository.Policy.Uniformity.Wave.Error) {
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
        let request = try uniformityWaveRequest(
            subject: subject,
            population: population.commitment,
            values: values
        )
        let result:
            (
                recovery: Repository.Policy.Uniformity.Wave.Recovery,
                receipt: Repository.Policy.Uniformity.Wave.Preflight
            )
        do throws(Repository.Policy.Uniformity.Wave.Error) {
            result = try await Repository.Policy.Uniformity.Wave.preflight(
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
            "institute repository: uniformity-wave preflight accepted \(repository) "
                + "recovery=\(result.receipt.recoveryDigest)"
        )
    }

    private static func applyUniformityWave(
        _ values: [String: String],
        client: RepositoryPolicy.GitHubClient
    ) async throws(Error) {
        let required = ["--recovery", "--payload", "--events", "--receipt"]
        try require(values, keys: required, operation: "apply")
        let recovery: Repository.Policy.Uniformity.Wave.Recovery = try decode(
            at: values["--recovery"]!,
            label: "uniformity-wave recovery"
        )
        let payload = try data(at: values["--payload"]!, label: "shape policy payload")
        let request = Repository.Policy.Uniformity.Wave.Request(
            repository: recovery.repository,
            expectedRepositoryID: recovery.repositoryID,
            expectedHead: recovery.rollbackHead,
            expectedManifest: recovery.manifest,
            expectedShape: recovery.shape,
            payload: payload,
            canonicalRuleset: recovery.canonicalRuleset,
            integrationID: recovery.integrationID,
            population: recovery.population,
            policyDigest: recovery.policyDigest,
            policySource: recovery.policySource,
            commitMessage: uniformityCommitMessage
        )
        let eventsURL = URL(filePath: values["--events"]!)
        let receipt: Repository.Policy.Uniformity.Wave.Receipt
        do throws(Repository.Policy.Uniformity.Wave.Error) {
            receipt = try await Repository.Policy.Uniformity.Wave.run(
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
            "institute repository: uniformity-wave \(receipt.changed ? "applied" : "converged") "
                + "\(receipt.repository) head=\(receipt.newHead) "
                + "gitignore=\(receipt.newGitignore) "
                + "deleted=\(receipt.deleted.count) bypass-closed=\(receipt.bypassClosed)"
        )
    }

    private static func closeUniformityWave(
        _ values: [String: String],
        client: RepositoryPolicy.GitHubClient
    ) async throws(Error) {
        let required = ["--recovery", "--payload", "--output"]
        try require(values, keys: required, operation: "close")
        let recovery: Repository.Policy.Uniformity.Wave.Recovery = try decode(
            at: values["--recovery"]!,
            label: "uniformity-wave recovery"
        )
        let payload = try data(at: values["--payload"]!, label: "shape policy payload")
        let closure: Repository.Policy.Uniformity.Wave.Closure
        do throws(Repository.Policy.Uniformity.Wave.Error) {
            closure = try await Repository.Policy.Uniformity.Wave.close(
                client: client,
                recovery: recovery,
                payload: payload
            )
        } catch {
            throw .wave(error)
        }
        try encode(closure, to: URL(filePath: values["--output"]!))
        guard closure.accepted else {
            throw .wave(
                .verification("\(closure.repository): uniformity closure was not accepted")
            )
        }
        print("institute repository: uniformity-wave closure accepted \(closure.repository)")
    }

    private static func recensusUniformityWave(
        _ values: [String: String],
        client: RepositoryPolicy.GitHubClient
    ) async throws(Error) {
        let required = [
            "--fleet", "--original", "--payload", "--receipts", "--events", "--closures",
            "--policy-digest", "--policy-source", "--output",
        ]
        try require(values, keys: required, operation: "recensus")
        let original: Repository.Policy.Uniformity.Wave.Population = try decode(
            at: values["--original"]!,
            label: "original uniformity-wave population"
        )
        let fleetPolicy = try fleet(at: values["--fleet"]!)
        let current: Repository.Policy.Uniformity.Wave.Population
        do throws(Repository.Policy.Uniformity.Wave.Error) {
            current = try await Repository.Policy.Uniformity.Wave.enumerate(
                client: client,
                fleet: fleetPolicy
            )
        } catch {
            throw .wave(error)
        }
        let payload = try data(at: values["--payload"]!, label: "shape policy payload")
        let receipts: [Repository.Policy.Uniformity.Wave.Receipt] = try decodeDirectory(
            at: values["--receipts"]!,
            label: "uniformity-wave receipts"
        )
        let closures: [Repository.Policy.Uniformity.Wave.Closure] = try decodeDirectory(
            at: values["--closures"]!,
            label: "uniformity-wave closures"
        )
        let events: [Repository.Policy.Uniformity.Wave.Event] = try decodeLinesDirectory(
            at: values["--events"]!,
            label: "uniformity-wave events"
        )
        let recensus: Repository.Policy.Uniformity.Wave.Recensus
        do throws(Repository.Policy.Uniformity.Wave.Error) {
            recensus = try Repository.Policy.Uniformity.Wave.recensus(
                original: original,
                current: current,
                evidence: .init(
                    payload: payload,
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
                    "uniformity recensus refused \(mismatches.count) subjects: "
                        + mismatches.joined(separator: ", ")
                )
            )
        }
        print(
            "institute repository: uniformity-wave recensus accepted "
                + "examined=\(recensus.examined) eligible=\(recensus.observations.count) "
                + "population=\(recensus.originalPopulation.subjectDigest)"
        )
    }

    private static func restoreUniformityWave(
        _ values: [String: String],
        client: RepositoryPolicy.GitHubClient
    ) async throws(Error) {
        guard values.count == 1, let path = values["--recovery"] else {
            throw waveConfiguration("uniformity-wave restore requires only --recovery <path>")
        }
        let recovery: Repository.Policy.Uniformity.Wave.Recovery = try decode(
            at: path,
            label: "uniformity-wave recovery"
        )
        guard let snapshot = recovery.priorRuleset else {
            print("institute repository: uniformity-wave recovery has no prior ruleset")
            return
        }
        do throws(Repository.Policy.Uniformity.Wave.Error) {
            try await Repository.Policy.Uniformity.Wave.restore(client: client, snapshot: snapshot)
        } catch {
            throw .wave(error)
        }
        print("institute repository: uniformity-wave restored \(recovery.repository)")
    }

    private static func uniformityWaveRequest(
        subject: Repository.Policy.Uniformity.Wave.Subject,
        population: Repository.Policy.Uniformity.Wave.Commitment,
        values: [String: String]
    ) throws(Error) -> Repository.Policy.Uniformity.Wave.Request {
        guard let integrationID = Int64(values["--integration-id"]!), integrationID > 0 else {
            throw waveConfiguration("uniformity-wave --integration-id must be a positive integer")
        }
        let policyDigest = values["--policy-digest"]!
        let policySource = values["--policy-source"]!
        guard policyDigest.count == 64, policySource.count == 40 else {
            throw waveConfiguration("uniformity-wave policy digest or source is not exact")
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
            expectedShape: subject.shape,
            payload: try data(at: values["--payload"]!, label: "shape policy payload"),
            canonicalRuleset: canonicalRuleset,
            integrationID: integrationID,
            population: population,
            policyDigest: policyDigest,
            policySource: policySource,
            commitMessage: uniformityCommitMessage
        )
    }

    /// The ratified transaction commit message. The `[skip ci]` suffix is
    /// mandatory: it is how the caller wave avoided 469 post-main
    /// matrices, and this wave rides the same discipline.
    private static var uniformityCommitMessage: String {
        "Adopt the canonical package shape policy [skip ci]"
    }
}
