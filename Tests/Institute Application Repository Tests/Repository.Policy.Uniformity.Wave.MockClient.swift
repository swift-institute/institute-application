import Institute_Repository_Policy
import Foundation
import Institute_Application_Foundation_Integration

actor RepositoryPolicyUniformityWaveMockClient: Repository.Policy.Uniformity.Wave.Client {
    var remainingRequests = 5_000
    var repository = Repository.Policy.Caller.Wave.Repository(
        id: 1,
        visibility: "public",
        archived: false,
        disabled: false,
        defaultBranch: "main"
    )
    var currentHead = "old-head"
    var oldShape: Repository.Policy.Uniformity.Wave.Shape
    var committedPayload = Data()
    var committedDeletions: [String] = []
    var newBlob = "new-blob"
    var rulesetData: Data
    var rulesetID: Int64?
    var replacementCount = 0
    var creationCount = 0
    var commitCount = 0
    var moveCount = 0
    var moveFailure = false
    var restorationFailure = false
    var convergenceFailure = false
    var persistentConvergenceFailure = false
    var moveHeadOnOpen = false
    var commitFailure = false
    var brokenBytesAfterMove = false
    var survivingDeletionAfterMove = false
    var pausedAttempts: [Int] = []
    let emptyRepositories: Bool
    let privateOrganizations: Set<String>

    init(
        ruleset: Data,
        shape: Repository.Policy.Uniformity.Wave.Shape,
        emptyRepositories: Bool = false,
        rulesetAbsent: Bool = false,
        privateOrganizations: Set<String> = []
    ) {
        rulesetData = ruleset
        oldShape = shape
        rulesetID = rulesetAbsent ? nil : 7
        self.emptyRepositories = emptyRepositories
        self.privateOrganizations = privateOrganizations
    }

    // MARK: - Uniformity surface

    func shapeFile(
        _: String,
        path: String,
        head: String
    ) async throws(RepositoryPolicy.GitHubClient.Error)
        -> Repository.Policy.Uniformity.Wave.File?
    {
        if head == "new-head" {
            switch path {
            case Repository.Policy.Uniformity.Wave.Shape.gitignorePath:
                if brokenBytesAfterMove {
                    return .init(blob: newBlob, bytes: Data("broken\n".utf8))
                }
                return .init(blob: newBlob, bytes: committedPayload)

            case Repository.Policy.Uniformity.Wave.Shape.swiftlintPath:
                return survivingDeletionAfterMove
                    ? .init(blob: "lint-blob", bytes: Data("lint\n".utf8)) : nil

            default:
                return nil
            }
        }
        switch path {
        case Repository.Policy.Uniformity.Wave.Shape.gitignorePath:
            return oldShape.gitignore

        case Repository.Policy.Uniformity.Wave.Shape.swiftlintPath:
            return oldShape.swiftlint.map { .init(blob: $0, bytes: Data("lint\n".utf8)) }

        case Repository.Policy.Uniformity.Wave.Shape.swiftFormatPath:
            return oldShape.swiftFormat.map { .init(blob: $0, bytes: Data("format\n".utf8)) }

        case Repository.Policy.Uniformity.Wave.Shape.dependabotPath:
            return oldShape.dependabot.map { .init(blob: $0, bytes: Data("dependabot\n".utf8)) }

        default:
            return nil
        }
    }

    func createShapeCommit(
        _: String,
        parent _: String,
        gitignoreBlob _: String,
        deletions: [String],
        message: String
    ) async throws(RepositoryPolicy.GitHubClient.Error) -> String {
        if commitFailure {
            throw .transport(path: "commit", message: "injected process interruption")
        }
        guard message.hasSuffix("[skip ci]") else {
            throw .precondition("commit message must carry the [skip ci] suffix")
        }
        committedDeletions = deletions
        commitCount += 1
        return "new-head"
    }

    // MARK: - Reused caller-wave surface

    func capacity(
        requiredRequests: Int
    ) async throws(RepositoryPolicy.GitHubClient.Error)
        -> Repository.Policy.Caller.Wave.Capacity
    {
        .init(remaining: remainingRequests, required: requiredRequests, resetAt: 1_787_000_000)
    }

    func waveRepositories(
        organization: String
    ) async throws(RepositoryPolicy.GitHubClient.Error)
        -> Repository.Policy.Caller.Wave.Listing
    {
        if emptyRepositories { return .init(repositories: [], expected: 0) }
        return .init(
            repositories: [
                .init(
                    id: 1,
                    name: "example",
                    fullName: "\(organization)/example",
                    visibility: privateOrganizations.contains(organization)
                        ? "private" : "public",
                    archived: false,
                    disabled: false,
                    fork: false,
                    size: 1
                )
            ],
            expected: 1
        )
    }

    func rootManifest(
        _: String,
        head _: String
    ) async throws(RepositoryPolicy.GitHubClient.Error)
        -> Repository.Policy.Caller.Wave.Manifest?
    {
        .init(kind: "file", blob: "manifest-blob")
    }

    func waveRepository(
        _: String
    ) async throws(RepositoryPolicy.GitHubClient.Error)
        -> Repository.Policy.Caller.Wave.Repository
    {
        repository
    }

    func head(_: String) async throws(RepositoryPolicy.GitHubClient.Error) -> String {
        currentHead
    }

    func callerSource(
        _ repository: String,
        head: String
    ) async throws(RepositoryPolicy.GitHubClient.Error)
        -> Repository.Policy.Caller.Wave.CallerSource
    {
        guard let source = try await callerSourceIfPresent(repository, head: head) else {
            throw .precondition("caller is absent")
        }
        return source
    }

    func callerSourceIfPresent(
        _: String,
        head _: String
    ) async throws(RepositoryPolicy.GitHubClient.Error)
        -> Repository.Policy.Caller.Wave.CallerSource?
    {
        .init(blob: "caller-blob", bytes: Data("caller\n".utf8))
    }

    func rulesets(
        _: String
    ) async throws(RepositoryPolicy.GitHubClient.Error)
        -> [Repository.Policy.Caller.Wave.RulesetReference]
    {
        rulesetID.map { [.init(id: $0, name: "Institute protected main")] } ?? []
    }

    func ruleset(
        _: String,
        id _: Int64
    ) async throws(RepositoryPolicy.GitHubClient.Error) -> Data {
        rulesetData
    }

    func replaceRuleset(
        _: String,
        id _: Int64,
        payload: Data
    ) async throws(RepositoryPolicy.GitHubClient.Error) {
        let object = try? JSONSerialization.jsonObject(with: payload) as? [String: Any]
        let bypass = object?["bypass_actors"] as? [Any] ?? []
        if bypass.isEmpty, convergenceFailure {
            if !persistentConvergenceFailure { convergenceFailure = false }
            throw .precondition("convergence failed")
        }
        if bypass.isEmpty, restorationFailure {
            throw .precondition("restore failed")
        }
        if !bypass.isEmpty, moveHeadOnOpen {
            currentHead = "concurrent-head"
        }
        rulesetData = payload
        replacementCount += 1
    }

    func createRuleset(
        _: String,
        payload: Data
    ) async throws(RepositoryPolicy.GitHubClient.Error) -> Int64 {
        guard rulesetID == nil else {
            throw .precondition("ruleset already exists")
        }
        rulesetID = 7
        rulesetData = payload
        creationCount += 1
        return 7
    }

    func createBlob(
        _: String,
        content: Data
    ) async throws(RepositoryPolicy.GitHubClient.Error) -> String {
        committedPayload = content
        return newBlob
    }

    func createCommit(
        _: String,
        parent _: String,
        blob _: String,
        message _: String
    ) async throws(RepositoryPolicy.GitHubClient.Error) -> String {
        throw .precondition("the uniformity wave never creates a caller commit")
    }

    func moveMain(
        _: String,
        to head: String
    ) async throws(RepositoryPolicy.GitHubClient.Error) {
        if moveFailure {
            throw .precondition("move failed")
        }
        moveCount += 1
        currentHead = head
    }

    func pause(attempt: Int) async {
        pausedAttempts.append(attempt)
    }

    // MARK: - Test controls

    func setHead(_ value: String) {
        currentHead = value
    }

    func setShape(_ value: Repository.Policy.Uniformity.Wave.Shape) {
        oldShape = value
    }

    func setMoveFailure() {
        moveFailure = true
    }

    func setRestorationFailure() {
        restorationFailure = true
    }

    func setConvergenceFailure(persistent: Bool = false) {
        convergenceFailure = true
        persistentConvergenceFailure = persistent
    }

    func setMoveHeadOnOpen() {
        moveHeadOnOpen = true
    }

    func setCommitFailure() {
        commitFailure = true
    }

    func setBrokenBytesAfterMove() {
        brokenBytesAfterMove = true
    }

    func setSurvivingDeletionAfterMove() {
        survivingDeletionAfterMove = true
    }

    func openBypass(integrationID: Int64) throws {
        guard var object = try JSONSerialization.jsonObject(with: rulesetData) as? [String: Any]
        else {
            throw RepositoryPolicy.GitHubClient.Error.precondition("ruleset is not an object")
        }
        object["bypass_actors"] = [
            [
                "actor_id": integrationID,
                "actor_type": "Integration",
                "bypass_mode": "always",
            ]
        ]
        rulesetData = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    func bypassOpen(integrationID: Int64) -> Bool {
        Repository.Policy.Caller.Wave.RulesetSnapshot.containsIntegration(
            rulesetData,
            integrationID: integrationID
        )
    }

    func replacements() -> Int {
        replacementCount
    }

    func creations() -> Int {
        creationCount
    }

    func commits() -> Int {
        commitCount
    }

    func moves() -> Int {
        moveCount
    }

    func deletions() -> [String] {
        committedDeletions
    }
}
