public import Command
public import Institute_Model
public import Institute_Source
public import JSON

extension Institute.Source.Command {
  public struct Prepare: Sendable, Command.`Protocol` {
    public var workspacePath: Swift.String
    public var linterExecutable: Swift.String?

    public init(
      workspacePath: Swift.String = "",
      linterExecutable: Swift.String? = nil
    ) {
      self.workspacePath = workspacePath
      self.linterExecutable = linterExecutable
    }

    public static var configuration: Command.Configuration {
      .init(name: "prepare", abstract: "Render and verify the local source profile.")
    }

    public static var schema: Command.Schema.Definition<Self> {
      .init {
        Command.Option(
          \.workspacePath,
          name: .long(.literal("workspace-path")),
          placeholder: "workspace.xcworkspace",
          help: .init(abstract: "The authoritative Xcode workspace.")
        )
        Command.Option(
          \.linterExecutable,
          name: .long(.literal("linter-executable")),
          placeholder: "path",
          help: .init(abstract: "Already-built structured linter to snapshot for this preparation.")
        )
      }
    }

    public mutating func validate() throws(Command.Error) {
      guard !workspacePath.isEmpty else {
        throw .validationFailed(reason: "--workspace-path is required")
      }
    }

    public mutating func run() async throws(Institute.Error) {
      _ = try Institute.Source.Command.context(workspace: workspacePath)
      let linter: Institute.Source.Application.Linter =
        linterExecutable.map {
          .local(executable: $0)
        } ?? .published
      let receipt = try await Institute.Source.Application().prepare(
        workspace: workspacePath,
        linter: linter
      )
      print(receipt.jsonString(sortKeys: true))
    }
  }
}
