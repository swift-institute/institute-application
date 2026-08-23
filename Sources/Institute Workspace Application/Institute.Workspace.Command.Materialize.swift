public import Command
public import Command_Schema
public import Institute_Model
import Institute_Development

extension Institute.Workspace.Command {
    /// `institute workspace materialize` — regenerate the fleet workspace
    /// from the effective selection through the local publication
    /// operation.
    public struct Materialize: Sendable, Command_Schema.Command.`Protocol` {
        public var jobs: Swift.Int?

        public init(jobs: Swift.Int? = nil) { self.jobs = jobs }

        public static var configuration: Command_Schema.Command.Configuration {
            .init(
                name: "materialize",
                abstract: "Materialize the fleet workspace from the effective selection."
            )
        }

        public static var schema: Command_Schema.Command.Schema.Definition<Self> {
            .init {
                Command_Schema.Command.Option(
                    \.jobs,
                    name: .long(.literal("jobs")),
                    placeholder: "n",
                    help: .init(
                        abstract: "Cap concurrent materialization jobs (defaults to 32)."
                    )
                )
            }
        }

        public mutating func run() async throws(Institute.Error) {
            let root = try Institute.Workspace.Command.root()
            let configuration = try Institute.Configuration.load(at: root.checkout)
            let selection = try Institute.Selection.effective(at: root.checkout, in: configuration)
            let specification = try Institute.Xcode.integration(selection.repositories)
            let receipt = try await Institute.Workspace.Materialization(
                root: root,
                specification: specification,
                jobs: jobs ?? 32
            ).run()
            print(
                "workspace: \(selection.repositories.count) subjects, "
                    + "\(specification.members.count) typed members, "
                    + "\(receipt.buildables.count) buildables, "
                    + "\(receipt.testables.values.count) testables, "
                    + "input \(receipt.input.digest)"
            )
        }
    }
}

extension Institute.Workspace {
    /// `institute workspace` — the workspace maintenance verbs.
    public enum Command: Sendable, Command_Schema.Command.`Protocol` {
        case materialize(Materialize)

        public static var configuration: Command_Schema.Command.Configuration {
            .init(name: "workspace", abstract: "Maintain the materialized fleet workspace.")
        }

        public static var schema: Command_Schema.Command.Schema.Definition<Self> {
            .init {
                Command_Schema.Command.Subcommand.Group {
                    Command_Schema.Command.Subcommand.Case(
                        "materialize",
                        help: .init(
                            abstract: "Materialize the fleet workspace from the selection."
                        ),
                        initial: { .init() },
                        map: Self.materialize
                    )
                }
            }
        }

        public mutating func run() async throws(Institute.Error) {
            switch self {
            case .materialize(var command):
                try await command.run()
                self = .materialize(command)
            }
        }
    }
}
