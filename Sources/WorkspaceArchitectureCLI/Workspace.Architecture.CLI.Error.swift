public import WorkspaceArchitectureIndex
public import WorkspaceArchitectureModel

extension Workspace.Architecture.CLI {
    /// Why `institute architecture validate` or `institute architecture
    /// index` could not complete.
    public enum Error: Swift.Error, Sendable, Equatable {
        case configuration(Swift.String)
        case noWorkspaceCheckout(searchedFrom: Swift.String)
        case derivation(Swift.String)
        case unstableIndex(first: Swift.String, second: Swift.String)
        case artifact(Workspace.Architecture.Index.Artifact.Error)
    }
}
