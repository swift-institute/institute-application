public import Command
public import Command_Schema
import Environment
public import Institute_Architecture_Model
public import Institute_Model
import Process

extension Institute.Architecture.CLI {
  /// Which architecture verb one invocation performs.
  public enum Action: Sendable, Equatable, Argument.Codable {
    case validate
    case index
    case ledger
    case prepare

    public init?(argument: Swift.String) {
      switch argument {
      case "validate": self = .validate
      case "index": self = .index
      case "ledger": self = .ledger
      case "prepare": self = .prepare
      default: return nil
      }
    }

    public var argumentDescription: Swift.String {
      switch self {
      case .validate: "validate"
      case .index: "index"
      case .ledger: "ledger"
      case .prepare: "prepare"
      }
    }
  }

  /// `institute architecture validate|index|ledger|prepare` — the architecture controls.
  public struct Command: Sendable, Command_Schema.Command.`Protocol` {
    public var modes: [Action]
    public var workspacePath: Swift.String
    public var outputPath: Swift.String
    public var ledgerPath: Swift.String
    public var repository: Swift.String
    public var repositoryPath: Swift.String
    public var dryRun: Swift.Bool

    public init(
      modes: [Action] = [],
      workspacePath: Swift.String = "",
      outputPath: Swift.String = "",
      ledgerPath: Swift.String = "",
      repository: Swift.String = "",
      repositoryPath: Swift.String = "",
      dryRun: Swift.Bool = false
    ) {
      self.modes = modes
      self.workspacePath = workspacePath
      self.outputPath = outputPath
      self.ledgerPath = ledgerPath
      self.repository = repository
      self.repositoryPath = repositoryPath
      self.dryRun = dryRun
    }

    public static var configuration: Command_Schema.Command.Configuration {
      .init(name: "architecture", abstract: "Validate or index the architecture record.")
    }

    public static var schema: Command_Schema.Command.Schema.Definition<Self> {
      .init {
        Command_Schema.Command.Positional<Self, Action>.Many(
          \.modes,
          name: "mode",
          placeholder: "validate|index|ledger|prepare",
          arity: .atMost(1),
          help: .init(abstract: "Architecture operation to perform.")
        )
        Command_Schema.Command.Option(
          \.ledgerPath,
          name: .long(.literal("ledger-path")),
          placeholder: "path",
          help: .init(abstract: "Read the canonical migration ledger from this path.")
        )
        Command_Schema.Command.Option(
          \.repository,
          name: .long(.literal("repository")),
          placeholder: "organization/name",
          help: .init(abstract: "Current repository coordinate to prepare.")
        )
        Command_Schema.Command.Option(
          \.repositoryPath,
          name: .long(.literal("repository-path")),
          placeholder: "path",
          help: .init(abstract: "Isolated exact-commit worktree to transform.")
        )
        Command_Schema.Command.Flag(
          \.dryRun,
          name: .long(.literal("dry-run")),
          help: .init(abstract: "Print the deterministic edit plan without writing.")
        )
        Command_Schema.Command.Option(
          \.outputPath,
          name: .long(.literal("output-path")),
          placeholder: "path",
          help: .init(
            abstract: "Write the initial durable migration ledger at this path."
          )
        )
        Command_Schema.Command.Option(
          \.workspacePath,
          name: .long(.literal("workspace-path")),
          placeholder: "path",
          help: .init(
            abstract: "Institute checkout this invocation resolves against."
          )
        )
      }
    }

    public mutating func validate() throws(Command_Schema.Command.Error) {
      guard modes.count == 1 else {
        throw .validationFailed(
          reason: "architecture operation must be validate, index, ledger, or prepare."
        )
      }
      if modes.first == .ledger, outputPath.isEmpty {
        throw .validationFailed(
          reason: "architecture ledger requires --output-path."
        )
      }
      if modes.first == .prepare,
        ledgerPath.isEmpty || repository.isEmpty || repositoryPath.isEmpty
      {
        throw .validationFailed(
          reason:
            "architecture prepare requires --ledger-path, --repository, "
            + "and --repository-path."
        )
      }
    }

    public mutating func run() async throws(Institute.Error) {
      let path: Swift.String
      if workspacePath.isEmpty {
        guard let working = Environment.read("PWD") else {
          throw .configuration("PWD is not available")
        }
        path = working
      } else {
        path = workspacePath
      }
      let status: Swift.Int32
      do throws(Institute.Architecture.CLI.Error) {
        switch modes.first {
        case .validate:
          status = try Institute.Architecture.CLI.validate(path: path)

        case .index:
          status = try Institute.Architecture.CLI.index(path: path)

        case .ledger:
          status = try Institute.Architecture.CLI.ledger(
            path: path,
            outputPath: outputPath
          )

        case .prepare:
          status = try Institute.Architecture.CLI.prepare(
            ledgerPath: ledgerPath,
            repository: repository,
            repositoryPath: repositoryPath,
            dryRun: dryRun
          )

        case nil:
          throw .configuration(
            "architecture operation must be validate, index, ledger, or prepare"
          )
        }
      } catch {
        throw .configuration(
          "architecture \(modes.first?.argumentDescription ?? "unknown"): \(error)"
        )
      }
      Process.Exit.normal(status)
    }
  }
}
