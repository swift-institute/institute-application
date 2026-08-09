public import WorkspaceArchitectureModel

extension Workspace.Architecture.Index.Artifact {
    /// Why a versioned Architecture Index artifact cannot be emitted or
    /// verified.
    public enum Error: Swift.Error, Sendable, Equatable {
        case incompleteMeasurement([Workspace.Architecture.Owner])
        case invalidCoverage
        case invalidValidation
        case malformed
        case unsupportedSchema(Swift.String)
        case digestMismatch(expected: Swift.String, actual: Swift.String)
    }
}
