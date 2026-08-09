private import WorkspaceArchitectureFacts
private import WorkspaceArchitectureGraph
private import WorkspaceArchitectureIndex
private import WorkspaceArchitectureValidation

extension Workspace.Architecture.CLI {
    /// Emits the complete, validated, versioned Architecture Index artifact.
    public static func index(
        path: Swift.String,
        report: (Swift.String) -> Swift.Void = { Swift.print($0) }
    ) throws(Error) -> Swift.Int32 {
        let root = try checkout(containing: path)
        let derived: Workspace.Architecture.Facts
        do throws(Workspace.Architecture.Facts.Error) {
            derived = try .derive(at: root)
        } catch {
            throw .derivation("\(error)")
        }
        let graph = Workspace.Architecture.Graph(facts: derived.facts, edges: derived.edges)
        let validation = Workspace.Architecture.Validator().validate(
            derived: derived,
            graph: graph,
            today: today()
        )
        do throws(Workspace.Architecture.Index.Artifact.Error) {
            let artifact = try Workspace.Architecture.Index.Artifact(
                facts: derived,
                graph: graph,
                validation: validation
            )
            report(artifact.rendered)
        } catch {
            throw .artifact(error)
        }
        return 0
    }
}
