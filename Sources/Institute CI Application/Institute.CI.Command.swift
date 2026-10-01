public import Command
public import Command_Schema
public import Institute_Model
public import Institute_CI_Model

extension Institute.CI {
    /// `institute ci` — the typed continuous-integration passthrough. The
    /// family owns its own argument grammar (`execute(_:)`); the router
    /// forwards the bare tokens.
    public struct Command: Sendable, Command_Schema.Command.`Protocol` {
        public var arguments: [Swift.String]

        public init(arguments: [Swift.String] = []) { self.arguments = arguments }

        public static var configuration: Command_Schema.Command.Configuration {
            .init(
                name: "ci",
                abstract: "Operate the reabsorbed Institute.CI domain.",
                discussion: """
                    Measure one checked-out package:

                      institute ci source --repository <owner/name> --revision <commit>
                        --root <package-root> --bundle <primitives|standards|institute>
                        --xcode-application </Applications/Xcode.app>
                        [--jobs <positive-count>] [--exit-policy <advisory|strict>]

                    --revision is an exact lowercase 40-character commit, --root an
                    absolute path, and --xcode-application an application under
                    /Applications. --exit-policy defaults to advisory.

                    Once the report is produced, the exit policy decides the status:
                      advisory  0 when the report is complete, with or without findings.
                      strict    0 when the report is complete with no error-severity
                                finding and no artifact or control finding; 1 otherwise.
                      both      2 when the report is incomplete.
                    Invalid arguments are rejected before measurement, and other
                    failures can end the command with other statuses.
                    """
            )
        }

        public static var schema: Command_Schema.Command.Schema.Definition<Self> {
            .init {
                Command_Schema.Command.Positional<Self, Swift.String>.Many(
                    \.arguments,
                    name: "arguments",
                    placeholder: "ci-arguments",
                    arity: .atLeast(0),
                    help: .init(abstract: "Arguments forwarded to the CI family grammar.")
                )
            }
        }

        public mutating func run() async throws(Institute.Error) {
            await Institute.CI.Command.execute(arguments)
        }
    }
}
