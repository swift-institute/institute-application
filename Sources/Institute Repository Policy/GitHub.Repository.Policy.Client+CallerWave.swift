import Institute_Repository_Policy
import Foundation

extension RepositoryPolicy.GitHubClient: Repository.Policy.Caller.Wave.Client {
    public func capacity(
        requiredRequests: Int
    ) async throws(Error) -> Repository.Policy.Caller.Wave.Capacity {
        try await callerWaveCapacity(requiredRequests: requiredRequests)
    }

    public func waveRepositories(
        organization: String
    ) async throws(Error) -> Repository.Policy.Caller.Wave.Listing {
        try await callerWaveRepositories(organization: organization)
    }

    public func rootManifest(
        _ repository: String,
        head: String
    ) async throws(Error) -> Repository.Policy.Caller.Wave.Manifest? {
        try await callerWaveManifest(repository, head: head)
    }

    public func waveRepository(
        _ name: String
    ) async throws(Error) -> Repository.Policy.Caller.Wave.Repository {
        try await callerWaveRepository(name)
    }

    public func head(_ repository: String) async throws(Error) -> String {
        try await callerWaveHead(repository)
    }

    public func callerSource(
        _ repository: String,
        head: String
    ) async throws(Error) -> Repository.Policy.Caller.Wave.CallerSource {
        try await callerWaveSource(repository, head: head)
    }

    public func callerSourceIfPresent(
        _ repository: String,
        head: String
    ) async throws(Error) -> Repository.Policy.Caller.Wave.CallerSource? {
        try await callerWaveSourceIfPresent(repository, head: head)
    }

    public func rulesets(
        _ repository: String
    ) async throws(Error)
        -> [Repository.Policy.Caller.Wave.RulesetReference]
    {
        try await callerWaveRulesets(repository)
    }

    public func ruleset(_ repository: String, id: Int64) async throws(Error) -> Data {
        try await callerWaveRuleset(repository, id: id)
    }

    public func replaceRuleset(
        _ repository: String,
        id: Int64,
        payload: Data
    ) async throws(Error) {
        try await callerWaveReplaceRuleset(repository, id: id, payload: payload)
    }

    public func createRuleset(
        _ repository: String,
        payload: Data
    ) async throws(Error) -> Int64 {
        try await callerWaveCreateRuleset(repository, payload: payload)
    }

    public func createBlob(_ repository: String, content: Data) async throws(Error) -> String {
        try await callerWaveCreateBlob(repository, content: content)
    }

    public func createCommit(
        _ repository: String,
        parent: String,
        blob: String,
        message: String
    ) async throws(Error) -> String {
        try await callerWaveCreateCommit(
            repository,
            parent: parent,
            blob: blob,
            message: message
        )
    }

    public func moveMain(_ repository: String, to head: String) async throws(Error) {
        try await callerWaveMoveMain(repository, to: head)
    }

    public func pause(attempt: Int) async {
        await callerWavePause(attempt: attempt)
    }
}
