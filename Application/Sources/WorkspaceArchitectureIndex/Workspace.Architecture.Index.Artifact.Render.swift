public import WorkspaceArchitectureFacts
public import WorkspaceArchitectureGraph
public import WorkspaceArchitectureModel

extension Workspace.Architecture.Index.Artifact {
    /// The exact canonical bytes represented as UTF-8 text.
    public var rendered: Swift.String {
        "digest\t\(digest)\n" + Self.payload(
            index: index,
            edges: edges,
            coverage: coverage
        )
    }

    static func payload(
        index: Workspace.Architecture.Index,
        edges: [Workspace.Architecture.Edge],
        coverage: Workspace.Architecture.Facts.Coverage
    ) -> Swift.String {
        let header = [
            "schema\t\(schema)",
            "version\t\(version)",
            "measurement\tcomplete\t\(coverage.measured.count)/\(coverage.required.count)",
            "index-digest\t\(index.digest)",
            "validation\tvalid",
        ]
        let entries = index.entries.map { entry in
            "entry\t\(entry.owner)\t\(entry.layer.name)\t\(entry.concept)"
                + "\tproducts=\(entry.productCount)\ttargets=\(entry.targetCount)"
                + "\tedges=\(entry.edgeCount)"
        }
        let edges = edges.map { edge in
            "edge\t\(edge.kind.name)\t\(edge.source)\t\(edge.destination)"
        }
        return (header + entries + edges).joined(separator: "\n")
    }
}
