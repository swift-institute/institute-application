public import Command
public import Command_Schema
public import Institute_Model
public import Institute_Inventory

extension Institute.Inventory.Command {
    /// `institute inventory regenerate` — refused here: the Institute
    /// application has no network transport.
    public struct Regenerate: Sendable, Command_Schema.Command.`Protocol` {
        public var dry: Bool

        public init(dry: Bool = false) { self.dry = dry }

        public static var configuration: Command_Schema.Command.Configuration {
            .init(name: "regenerate", abstract: "Regenerate the inventory (no transport here).")
        }

        public static var schema: Command_Schema.Command.Schema.Definition<Self> {
            .init {
                Command_Schema.Command.Flag(
                    \.dry,
                    name: .long(.literal("dry-run")),
                    help: .init(
                        abstract: "Plan inventory regeneration without changing files."
                    )
                )
            }
        }

        public mutating func run() async throws(Institute.Error) {
            throw .configuration(
                "inventory regenerate has no network transport in the Institute application"
            )
        }
    }
}
