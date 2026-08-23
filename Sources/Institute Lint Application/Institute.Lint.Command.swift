public import Command
public import Command_Schema
public import Institute_Model
import Environment
import File_System
public import Institute_Lint
import Process

extension Institute.Lint.Command {
    /// The optional second positional of `institute lint`.
    public enum Mode: Sendable, Equatable, Argument.Codable {
        case install
        case check
        case ledger

        public init?(argument: Swift.String) {
            switch argument {
            case "install": self = .install
            case "check": self = .check
            case "ledger": self = .ledger
            default: return nil
            }
        }

        public var argumentDescription: Swift.String {
            switch self {
            case .install: "install"
            case .check: "check"
            case .ledger: "ledger"
            }
        }
    }
}

extension Institute.Lint {
    /// `institute lint [install|check|ledger]` — without a mode, the
    /// ecosystem sweep.
    public struct Command: Sendable, Command_Schema.Command.`Protocol` {
        public var modes: [Mode]
        public var fix: Bool
        public var dry: Bool
        public var changed: Bool
        public var workspacePath: Swift.String
        public var output: Swift.String
        public var dispositions: [Swift.String]
        public var verifications: [Swift.String]

        public init(
            modes: [Mode] = [],
            fix: Bool = false,
            dry: Bool = false,
            changed: Bool = false,
            workspacePath: Swift.String = "",
            output: Swift.String = "",
            dispositions: [Swift.String] = [],
            verifications: [Swift.String] = []
        ) {
            self.modes = modes
            self.fix = fix
            self.dry = dry
            self.changed = changed
            self.workspacePath = workspacePath
            self.output = output
            self.dispositions = dispositions
            self.verifications = verifications
        }

        public static var configuration: Command_Schema.Command.Configuration {
            .init(name: "lint", abstract: "Sweep the ecosystem with the pinned swift-linter.")
        }

        public static var schema: Command_Schema.Command.Schema.Definition<Self> {
            .init {
                Command_Schema.Command.Positional<Self, Mode>.Many(
                    \.modes,
                    name: "mode",
                    placeholder: "install|check|ledger",
                    arity: .atMost(1),
                    help: .init(
                        abstract:
                            "Optional lint verb; without one, the ecosystem sweep. Use "
                            + "lint ledger for the complete residual compliance report."
                    )
                )
                Command_Schema.Command.Flag(
                    \.fix,
                    name: .long(.literal("fix")),
                    help: .init(
                        abstract:
                            "Apply the canonical fix of every rewriter-backed rule instead of "
                            + "reporting findings (sweep only). Add --dry-run to print the "
                            + "diffs without writing."
                    )
                )
                Command_Schema.Command.Flag(
                    \.dry,
                    name: .long(.literal("dry-run")),
                    help: .init(
                        abstract: "With --fix, print the diffs without writing."
                    )
                )
                Command_Schema.Command.Flag(
                    \.changed,
                    name: .long(.literal("changed")),
                    help: .init(
                        abstract:
                            "Sweep only packages with local work — an unclean worktree, or "
                            + "commits not yet in the tracked upstream (sweep only)."
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
                Command_Schema.Command.Option(
                    \.output,
                    name: .long(.literal("format")),
                    placeholder: "human|json",
                    help: .init(
                        abstract:
                            "Render a concise human summary or deterministic JSON "
                            + "(ledger only; defaults to human)."
                    )
                )
                Command_Schema.Command.Option<Self, Swift.String>.Many(
                    \.dispositions,
                    name: .long(.literal("disposition")),
                    placeholder: "rule=state@owner/repository#N",
                    help: .init(
                        abstract:
                            "Supply one terminal advisory disposition and exact owner Issue "
                            + "(ledger only; repeatable)."
                    )
                )
                Command_Schema.Command.Option<Self, Swift.String>.Many(
                    \.verifications,
                    name: .long(.literal("verification")),
                    placeholder: "owner/repository@sha=actions-run-url",
                    help: .init(
                        abstract:
                            "Supply one exact-head successful GitHub Actions coordinate "
                            + "(ledger only; repeatable)."
                    )
                )
            }
        }

        public mutating func validate() throws(Command_Schema.Command.Error) {
            guard modes.isEmpty || !changed else {
                throw .validationFailed(reason: "--changed is valid only with the lint sweep.")
            }
            // `--fix --dry-run` is the preview of a fix run — the one place
            // `--dry-run` means something here, and the only place it does.
            guard !dry || fix else {
                throw .validationFailed(reason: "--dry-run is valid only with --fix here.")
            }
            guard modes.first != .ledger || (!fix && !dry) else {
                throw .validationFailed(
                    reason: "lint ledger is read-only; --fix and --dry-run are not valid."
                )
            }
            guard modes.isEmpty || !fix else {
                throw .validationFailed(reason: "--fix is valid only with the lint sweep.")
            }
            let ledger = modes.first == .ledger
            guard output.isEmpty || output == "human" || output == "json" else {
                throw .validationFailed(reason: "--format must be human or json.")
            }
            guard ledger || (output.isEmpty && dispositions.isEmpty && verifications.isEmpty)
            else {
                throw .validationFailed(
                    reason:
                        "--format, --disposition, and --verification are valid only with "
                        + "lint ledger."
                )
            }
            if ledger {
                var dispositionRules = Swift.Set<Swift.String>()
                for value in dispositions {
                    guard let disposition = Institute.Lint.Ledger.Disposition(argument: value)
                    else {
                        throw .validationFailed(
                            reason:
                                "invalid disposition \(value); expected "
                                + "rule=state@owner/repository#N."
                        )
                    }
                    guard dispositionRules.insert(disposition.rule).inserted else {
                        throw .validationFailed(
                            reason: "duplicate disposition for rule \(disposition.rule)."
                        )
                    }
                }
                var verificationRepositories = Swift.Set<Institute.Repository.Key>()
                for value in verifications {
                    guard let verification = Institute.Lint.Ledger.Verification(argument: value)
                    else {
                        throw .validationFailed(
                            reason:
                                "invalid verification \(value); expected "
                                + "owner/repository@<40-hex-sha>=<actions-run-url>."
                        )
                    }
                    guard verificationRepositories.insert(verification.repository).inserted
                    else {
                        throw .validationFailed(
                            reason:
                                "duplicate verification for "
                                + "\(verification.repository.identity)."
                        )
                    }
                }
            }
        }

        public mutating func run() async throws(Institute.Error) {
            let checkoutValue: Swift.String
            if workspacePath.isEmpty {
                guard let working = Environment.read("PWD") else {
                    throw .configuration("PWD is not available")
                }
                checkoutValue = working
            } else {
                checkoutValue = workspacePath
            }
            let checkout: File.Directory
            do throws(File.Path.Error) {
                checkout = try File.Directory(validating: checkoutValue)
            } catch {
                throw .configuration("Institute checkout is not a valid path: \(error)")
            }
            let root = try Institute.Root(checkout: checkout)
            let lint = Institute.Lint(root: root)
            switch modes.first {
            case .some(.install):
                // Install the installation `--fix` would resolve, not the
                // one this process happens to be standing next to. The two
                // rules disagreed — `--fix` ascends from the linted package,
                // `install` took the cwd's parent — so an install run from
                // anywhere else refreshed a different tree and reported
                // success while the lint run kept refusing on the tree it
                // had actually reached. Falling back to the checkout-derived
                // hierarchy keeps the first install on a fresh machine
                // working, where there is no installation to ascend to.
                let target = Institute.Lint.existing(from: checkoutValue) ?? lint
                try target.install()
                let manifest = try target.installedManifest()
                print("lint: installed swift-linter \(manifest.digest)")
                print("lint: \(try target.executable(for: manifest))")
                // Always name the installation that was written. A success
                // line that does not say *which* installation is exactly
                // what let eight consecutive successful installs leave the
                // refusing tree untouched.
                print("lint: installation \(target.manifestFile)")

            case .some(.check):
                let diagnostics = try lint.diagnostics()
                guard diagnostics.isEmpty else {
                    throw .configuration(diagnostics.joined(separator: "\n"))
                }
                print("lint: current — digest \(try lint.installedManifest().digest) matches CI")

            case .some(.ledger):
                let dispositions = self.dispositions.compactMap(
                    Institute.Lint.Ledger.Disposition.init(argument:)
                )
                let verifications = self.verifications.compactMap(
                    Institute.Lint.Ledger.Verification.init(argument:)
                )
                let configuration = try Institute.Configuration.load(at: root.checkout)
                let report = try await Institute.Lint.Sweep(
                    lint: lint,
                    root: root,
                    repositories: configuration.repositories
                ).ledger(dispositions: dispositions, verifications: verifications)
                if output == "json" {
                    print(report.json, terminator: "")
                } else {
                    print(report.description, terminator: "")
                }
                Process.Exit.normal(report.status)

            case nil:
                let fixMode: Institute.Lint.Fix? = fix ? (dry ? .dryRun : .apply) : nil
                if fixMode != nil {
                    guard Institute.Lint.supportsFix(try lint.installation()) else {
                        throw .configuration(Institute.Lint.fixUnsupported)
                    }
                    // Same discipline as the single-package path: the
                    // sweep refuses in the sweep's own vocabulary rather
                    // than as a thrown error, so a reader scanning for
                    // UNMEASURED finds it and an exit code of 2 separates
                    // it from both 0 (clean) and 1 (violations).
                    if let reason = try lint.currency().reason {
                        print("lint all: UNMEASURED — \(reason)")
                        print(
                            "lint all: 0 packages linted; no repository in this sweep has been "
                                + "measured, and none may be recorded clean"
                        )
                        Process.Exit.normal(2)
                    }
                }
                let configuration = try Institute.Configuration.load(at: root.checkout)
                let report = try await Institute.Lint.Sweep(
                    lint: lint,
                    root: root,
                    repositories: configuration.repositories
                ).run(scope: changed ? .changed : .all, fix: fixMode)
                print(report)
                Process.Exit.normal(report.status)
            }
        }
    }
}
