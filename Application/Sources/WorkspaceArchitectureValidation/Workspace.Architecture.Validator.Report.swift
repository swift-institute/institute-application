public import WorkspaceArchitectureFacts
public import WorkspaceArchitectureGraph
public import WorkspaceArchitectureModel

extension Workspace.Architecture.Validator {
    /// The outcome of one validation pass.
    public struct Report: Sendable, Equatable {
        /// The complete derived population this result validated.
        public let derived: Workspace.Architecture.Facts
        /// The graph over ``derived`` this result validated.
        public let graph: Workspace.Architecture.Graph
        /// Violations no valid exemption covers; any entry fails the run.
        public let violations: [Workspace.Architecture.Violation]
        /// Violations an unexpired, scope- and owner-matching exemption
        /// covers.
        public let excused: [Workspace.Architecture.Violation]

        init(
            derived: Workspace.Architecture.Facts,
            graph: Workspace.Architecture.Graph,
            violations: [Workspace.Architecture.Violation],
            excused: [Workspace.Architecture.Violation]
        ) {
            self.derived = derived
            self.graph = graph
            self.violations = violations
            self.excused = excused
        }
    }
}

extension Workspace.Architecture.Validator.Report {
    public var passes: Swift.Bool {
        violations.isEmpty
    }
}
