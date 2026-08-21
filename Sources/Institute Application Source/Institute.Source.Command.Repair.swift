public import Command
public import Institute_Model

extension Institute.Source.Command {
    public enum Repair: Sendable, Command.`Protocol` {
        case plan(Plan)
        case apply(Apply)

        public init() { self = .plan(.init()) }

        public static var configuration: Command.Configuration {
            .init(name: "repair", abstract: "Plan or apply a source repair transaction.")
        }

        public static var schema: Command.Schema.Definition<Self> {
            .init {
                Command.Subcommand.Group {
                    Command.Subcommand.Case("plan", initial: Plan.init, map: Self.plan)
                    Command.Subcommand.Case("apply", initial: Apply.init, map: Self.apply)
                }
            }
        }

        public mutating func run() async throws(Institute.Error) {
            switch self {
            case .plan(var command): try await command.run(); self = .plan(command)
            case .apply(var command): try await command.run(); self = .apply(command)
            }
        }
    }
}

extension Institute.Source.Command.Repair {
    public struct Plan: Sendable, Command.`Protocol` {
        public init() {}
        public static var configuration: Command.Configuration { .init(name: "plan") }
        public static var schema: Command.Schema.Definition<Self> { .init {} }
        public mutating func run() async throws(Institute.Error) {
            throw .configuration("source repair planning is not yet available")
        }
    }

    public struct Apply: Sendable, Command.`Protocol` {
        public init() {}
        public static var configuration: Command.Configuration { .init(name: "apply") }
        public static var schema: Command.Schema.Definition<Self> { .init {} }
        public mutating func run() async throws(Institute.Error) {
            throw .configuration("source repair application is not yet available")
        }
    }
}
