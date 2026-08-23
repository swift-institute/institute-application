public import Command
public import Institute_Model
public import Institute_Source
public import JSON

extension Institute.Source.Command {
  public struct Prepare: Sendable, Command.`Protocol` {
    public var workspacePath: Swift.String

    public init(workspacePath: Swift.String = "") { self.workspacePath = workspacePath }

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
      }
    }

    public mutating func validate() throws(Command.Error) {
      guard !workspacePath.isEmpty else {
        throw .validationFailed(reason: "--workspace-path is required")
      }
    }

    public mutating func run() async throws(Institute.Error) {
      _ = try Institute.Source.Command.context(workspace: workspacePath)
      let receipt = try await Institute.Source.Application().prepare(workspace: workspacePath)
      print(receipt.jsonString(sortKeys: true))
    }
  }
}
