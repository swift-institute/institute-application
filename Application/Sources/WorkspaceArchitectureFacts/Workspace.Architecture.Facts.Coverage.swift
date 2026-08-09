public import WorkspaceArchitectureModel

extension Workspace.Architecture.Facts {
    /// The manifest measurement state for the inventory population.
    ///
    /// A required owner is measured only when its manifest was read. Missing
    /// manifests stay explicit here; they never become empty package facts.
    public struct Coverage: Sendable, Equatable {
        public let required: [Workspace.Architecture.Owner]
        public let measured: [Workspace.Architecture.Owner]

        public init(
            required: [Workspace.Architecture.Owner],
            measured: [Workspace.Architecture.Owner]
        ) {
            self.required = required.sorted()
            self.measured = measured.sorted()
        }
    }
}

extension Workspace.Architecture.Facts.Coverage {
    /// Required owners whose manifests were not measured.
    public var unmeasured: [Workspace.Architecture.Owner] {
        let measured = Swift.Set(measured)
        return required.filter { !measured.contains($0) }
    }

    /// Whether the full required inventory population was measured.
    public var complete: Swift.Bool {
        unmeasured.isEmpty
    }
}
