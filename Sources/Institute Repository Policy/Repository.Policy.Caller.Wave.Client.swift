import Institute_Repository_Policy
import Foundation

extension Repository.Policy.Caller.Wave {
    public protocol Client: Sendable {
        func capacity(
            requiredRequests: Int
        ) async throws(RepositoryPolicy.GitHubClient.Error) -> Capacity
        func waveRepositories(
            organization: String
        ) async throws(RepositoryPolicy.GitHubClient.Error) -> Listing
        func rootManifest(
            _ repository: String,
            head: String
        ) async throws(RepositoryPolicy.GitHubClient.Error) -> Manifest?
        func waveRepository(
            _ name: String
        ) async throws(RepositoryPolicy.GitHubClient.Error)
            -> Repository
        func head(_ repository: String) async throws(RepositoryPolicy.GitHubClient.Error) -> String
        func callerSource(
            _ repository: String,
            head: String
        ) async throws(RepositoryPolicy.GitHubClient.Error) -> CallerSource
        func callerSourceIfPresent(
            _ repository: String,
            head: String
        ) async throws(RepositoryPolicy.GitHubClient.Error) -> CallerSource?
        func rulesets(
            _ repository: String
        ) async throws(RepositoryPolicy.GitHubClient.Error) -> [RulesetReference]
        func ruleset(
            _ repository: String,
            id: Int64
        ) async throws(RepositoryPolicy.GitHubClient.Error) -> Data
        func replaceRuleset(
            _ repository: String,
            id: Int64,
            payload: Data
        ) async throws(RepositoryPolicy.GitHubClient.Error)
        func createRuleset(
            _ repository: String,
            payload: Data
        ) async throws(RepositoryPolicy.GitHubClient.Error) -> Int64
        func createBlob(
            _ repository: String,
            content: Data
        ) async throws(RepositoryPolicy.GitHubClient.Error) -> String
        func createCommit(
            _ repository: String,
            parent: String,
            blob: String,
            message: String
        ) async throws(RepositoryPolicy.GitHubClient.Error) -> String
        func moveMain(
            _ repository: String,
            to head: String
        ) async throws(RepositoryPolicy.GitHubClient.Error)
        func pause(attempt: Int) async
    }
}
