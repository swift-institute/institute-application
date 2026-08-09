public import WorkspaceArchitectureFacts
public import WorkspaceArchitectureGraph
public import WorkspaceArchitectureModel
public import WorkspaceArchitectureValidation

extension Workspace.Architecture.Index {
    /// A versioned, complete, validated, deterministic Index transport
    /// artifact for downstream host-control consumers.
    public struct Artifact: Sendable, Equatable {
        public let index: Workspace.Architecture.Index
        public let edges: [Workspace.Architecture.Edge]
        public let coverage: Workspace.Architecture.Facts.Coverage
        public let digest: Workspace.Architecture.Index.Digest

        public init(
            facts: Workspace.Architecture.Facts,
            validation: Workspace.Architecture.Validator.Report
        ) throws(Error) {
            guard facts.coverage.complete else {
                throw .incompleteMeasurement(facts.coverage.unmeasured)
            }
            let owners = facts.facts.map(\.owner)
            guard facts.coverage.required == owners, facts.coverage.measured == owners else {
                throw .invalidCoverage
            }
            let graph = facts.graph
            guard validation.derived == facts, validation.graph == graph, validation.passes
            else { throw .invalidValidation }
            let edges = Swift.Array(Swift.Set(graph.edges)).sorted()
            let index = Workspace.Architecture.Index.generate(
                facts: facts.facts,
                graph: .init(facts: facts.facts, edges: edges)
            )
            let coverage = facts.coverage
            self.index = index
            self.edges = edges
            self.coverage = coverage
            self.digest = .init(text: Self.payload(
                index: index,
                edges: edges,
                coverage: coverage
            ))
        }
    }
}

extension Workspace.Architecture.Index.Artifact {
    /// The stable artifact schema identity.
    public static let schema = "workspace.architecture.index"

    /// The stable artifact schema version.
    public static let version = 1
}
