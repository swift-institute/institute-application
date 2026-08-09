public import WorkspaceArchitectureModel

extension Workspace.Architecture.Index.Artifact {
    /// Refuses malformed, incompatible, or tampered canonical bytes.
    public static func verify(_ rendered: Swift.String) throws(Error) {
        let lines = rendered.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.count >= 6 else { throw .malformed }
        let digest = Swift.String(lines[0])
        guard digest.hasPrefix("digest\t") else { throw .malformed }
        let claimed = Swift.String(digest.dropFirst("digest\t".count))
        let payload = lines.dropFirst().joined(separator: "\n")
        guard lines[1] == "schema\t\(schema)" else {
            throw .unsupportedSchema(Swift.String(lines[1]))
        }
        guard lines[2] == "version\t\(version)" else {
            throw .unsupportedSchema(Swift.String(lines[2]))
        }
        guard lines[3].hasPrefix("measurement\tcomplete\t") else { throw .malformed }
        guard lines[4].hasPrefix("index-digest\t") else { throw .malformed }
        guard lines[5] == "validation\tvalid" else { throw .malformed }
        let actual = Workspace.Architecture.Index.Digest(text: payload).description
        guard claimed == actual else {
            throw .digestMismatch(expected: claimed, actual: actual)
        }
    }
}
