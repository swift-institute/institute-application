public import Environment
public import File_System
public import Institute_Model
public import Institute_Source
public import JSON
public import Process

extension Institute.Source.Command {
    static func context(workspace: Swift.String) throws(Institute.Error) -> (
        root: Institute.Root,
        configuration: Institute.Configuration,
        cohort: Institute.Source.Workspace.Cohort
    ) {
        guard !workspace.isEmpty else { throw .configuration("--workspace-path is required") }
        let workspacePath: File.Path
        do throws(File.Path.Error) { workspacePath = try .init(workspace) }
        catch { throw .configuration("invalid --workspace-path \(workspace)") }
        guard let checkout = File.Directory(workspacePath).parent else {
            throw .configuration("workspace has no containing Institute checkout")
        }
        let root = try Institute.Root(checkout: checkout)
        let configuration = try Institute.Configuration.load(at: root.checkout)
        return (
            root,
            configuration,
            try Institute.Source.Workspace.Cohort.read(
                from: workspace,
                configuration: configuration,
                hierarchy: root.hierarchy
            )
        )
    }

    static func preparation(workspace: Swift.String) throws(Institute.Error) -> Institute.Source.Preparation {
        let directory = try Institute.Source.Application.artifactDirectory(workspace: workspace)
        let receipt = directory[file: "receipt.json"]
        let bytes: [Byte]
        do throws(Either<File.System.Read.Full.Error, Never>) {
            bytes = try File.System.Read.Full.read(from: receipt.path) { span in
                var result: [Byte] = []
                result.reserveCapacity(span.count)
                for index in span.indices { result.append(span[index]) }
                return result
            }
        } catch { throw .configuration("source preparation missing; run source prepare") }
        do throws(JSON.Error) {
            return try .init(jsonString: Swift.String(decoding: bytes, as: Swift.UTF8.self))
        } catch { throw .configuration("source preparation receipt is malformed: \(error)") }
    }

    static func executable(
        _ name: Swift.String,
        resolver: Swift.String,
        arguments: [Swift.String]
    ) throws(Institute.Error) -> Swift.String {
        let output: Process.Output
        do throws(Process.Error) {
            output = try Process.Spawn.run(
                .init(executable: resolver, arguments: arguments, stdout: .pipe, stderr: .pipe)
            )
        } catch { throw .configuration("cannot resolve \(name): \(error)") }
        guard case .exited(0) = output.status else {
            throw .configuration("cannot resolve \(name)")
        }
        guard let line = Swift.String(decoding: output.stdout ?? [], as: Swift.UTF8.self)
            .split(whereSeparator: \.isNewline).first
        else { throw .configuration("cannot resolve \(name)") }
        return Swift.String(line)
    }

    static func write(_ contents: Swift.String, to output: Swift.String) throws(Institute.Error) {
        guard !output.isEmpty else { print(contents, terminator: ""); return }
        let path: File.Path
        do throws(File.Path.Error) { path = try .init(output) }
        catch { throw .configuration("invalid --output-path \(output)") }
        do throws(File.System.Write.Atomic.Error) { try File(path).write.atomic(contents) }
        catch { throw .filesystem("cannot write --output-path \(output): \(error)") }
    }
}
