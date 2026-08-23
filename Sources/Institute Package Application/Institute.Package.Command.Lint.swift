public import Command
public import Command_Schema
public import Institute_Model
import Environment
import Institute_Lint
import Process
import File_System

extension Institute.Package.Command {
    /// `institute package lint` — the inner-loop single-package lint. It
    /// reads no inventory, enumerates no organisation, and constructs no
    /// `Institute.Root`: standing inside a package, the package root and
    /// the installed binaries are both reachable by walking up. That is
    /// what keeps this mode from paying ecosystem-scale costs.
    public struct Lint: Sendable, Command_Schema.Command.`Protocol` {
        public var packagePath: Swift.String
        public var fix: Bool
        public var dry: Bool

        public init(
            packagePath: Swift.String = "",
            fix: Bool = false,
            dry: Bool = false
        ) {
            self.packagePath = packagePath
            self.fix = fix
            self.dry = dry
        }

        public static var configuration: Command_Schema.Command.Configuration {
            .init(name: "lint", abstract: "Lint one package with the pinned swift-linter.")
        }

        public static var schema: Command_Schema.Command.Schema.Definition<Self> {
            .init {
                Command_Schema.Command.Option(
                    \.packagePath,
                    name: .long(.literal("package-path")),
                    placeholder: "path",
                    help: .init(
                        abstract: "Package root for the operation (defaults to PWD)."
                    )
                )
                Command_Schema.Command.Flag(
                    \.fix,
                    name: .long(.literal("fix")),
                    help: .init(
                        abstract:
                            "Apply the canonical fix of every rewriter-backed rule instead of "
                            + "reporting findings. Add --dry-run to print the diffs without "
                            + "writing."
                    )
                )
                Command_Schema.Command.Flag(
                    \.dry,
                    name: .long(.literal("dry-run")),
                    help: .init(
                        abstract: "With --fix, print the diffs without writing."
                    )
                )
            }
        }

        public mutating func validate() throws(Command_Schema.Command.Error) {
            guard !dry || fix else {
                throw .validationFailed(reason: "--dry-run is valid only with --fix here.")
            }
        }

        public mutating func run() async throws(Institute.Error) {
            guard let working = Environment.read("PWD") else {
                throw .configuration("PWD is not available")
            }
            let target = try Institute.Lint.Target.resolve(
                packagePath.isEmpty ? working : packagePath
            )
            let lint = try Institute.Lint.resolve(from: target.package.description)
            // The default bundle comes from where the package sits under
            // the hierarchy the installation was found in — the same
            // ascent, no extra reads. It is used only when the package
            // carries no `Lint.swift`.
            let installation = try lint.installation()
            let mode: Institute.Lint.Fix? = fix ? (dry ? .dryRun : .apply) : nil
            if mode != nil {
                guard Institute.Lint.supportsFix(installation) else {
                    throw .configuration(Institute.Lint.fixUnsupported)
                }
                // A refusal is reported as a measurement, never thrown.
                // Thrown, it left the report entirely: a lane saw
                // swift-format clean, swiftlint clean, and no swift-linter
                // line at all, and absence of a finding read as absence of
                // findings. As an UNMEASURED verdict it occupies the same
                // line, the same word, and the same exit code as every
                // other run that established nothing.
                if let reason = try lint.currency().reason {
                    let refused = Institute.Lint.Measurement(
                        package: target.package.description,
                        verdict: .unmeasured(reason: reason),
                        summary: nil,
                        plan: nil,
                        findings: [],
                        structured: nil,
                        prerequisite: .currency,
                        diagnostics: "",
                        status: 0
                    )
                    print(refused)
                    Process.Exit.normal(2)
                }
                // The shadow gate, first tier only. The inner loop stands
                // inside one package and reads no inventory, so the
                // re-export tier — which needs the population to resolve a
                // module to the package providing it — has nothing to
                // resolve against and is not attempted. The sweep is where
                // it runs, and the sweep is what dispatches the fleet.
                let exclusions: [Swift.String]
                if let exclusion = Institute.Lint.Shadow.exclusion(
                    for: Institute.Lint.Shadow.scan(target.package)
                ) {
                    print("\(exclusion)")
                    print(
                        "          PLAT-ARCH-022 qualification is unsound here; "
                            + "it is excluded while other safe fixes proceed"
                    )
                    exclusions = [Institute.Lint.Fix.shadowedStandardLibraryQualification]
                } else {
                    exclusions = []
                }
                let measurement = lint.measure(
                    target,
                    using: installation,
                    default: Institute.Lint.Bundle.resolve(
                        target.package,
                        under: lint.hierarchy
                    ),
                    fix: mode,
                    excluding: exclusions
                )
                print(measurement)
                Process.Exit.normal(
                    measurement.verdict.fails ? (measurement.verdict.isUnmeasured ? 2 : 1) : 0
                )
            }
            let measurement = lint.measure(
                target,
                using: installation,
                default: Institute.Lint.Bundle.resolve(
                    target.package,
                    under: lint.hierarchy
                ),
                fix: mode
            )
            print(measurement)
            Process.Exit.normal(
                measurement.verdict.fails ? (measurement.verdict.isUnmeasured ? 2 : 1) : 0
            )
        }
    }

    /// `institute package check` — the local CI-parity gate. Same
    /// inner-loop ascent as `package lint`: no inventory, no
    /// `Institute.Root`, just the package root and the installed
    /// swift-linter reached by walking up from wherever the caller stands.
    public struct Check: Sendable, Command_Schema.Command.`Protocol` {
        public var packagePath: Swift.String
        public var jobs: Swift.Int?
        public var fresh: Bool

        public init(
            packagePath: Swift.String = "",
            jobs: Swift.Int? = nil,
            fresh: Bool = false
        ) {
            self.packagePath = packagePath
            self.jobs = jobs
            self.fresh = fresh
        }

        public static var configuration: Command_Schema.Command.Configuration {
            .init(name: "check", abstract: "Run the local CI-parity gate on one package.")
        }

        public static var schema: Command_Schema.Command.Schema.Definition<Self> {
            .init {
                Command_Schema.Command.Option(
                    \.packagePath,
                    name: .long(.literal("package-path")),
                    placeholder: "path",
                    help: .init(
                        abstract: "Package root for the operation (defaults to PWD)."
                    )
                )
                Command_Schema.Command.Option(
                    \.jobs,
                    name: .long(.literal("jobs")),
                    placeholder: "n",
                    help: .init(
                        abstract: "Cap compile jobs the coordinator gives SwiftPM."
                    )
                )
                Command_Schema.Command.Flag(
                    \.fresh,
                    name: .long(.literal("fresh")),
                    help: .init(
                        abstract: "Use isolated build state — a scratch directory."
                    )
                )
            }
        }

        public mutating func run() async throws(Institute.Error) {
            guard let working = Environment.read("PWD") else {
                throw .configuration("PWD is not available")
            }
            let target = try Institute.Lint.Target.resolve(
                packagePath.isEmpty ? working : packagePath
            )
            let lint = try Institute.Lint.resolve(from: target.package.description)
            let check = Institute.Lint.Check(lint)
            let report = check.run(target, jobs: jobs, fresh: fresh)
            print(report)
            Process.Exit.normal(report.fails ? 1 : 0)
        }
    }
}
