public import Command
public import Institute_Model
public import Institute_Source
public import Process

extension Institute.Source.Command {
    public struct Measure: Sendable, Command.`Protocol` {
        public var workspacePath: Swift.String
        public var changed: Swift.Bool
        public var packagePaths: [Swift.String]
        public var engines: [Swift.String]
        public var jobs: Swift.Int?
        public var format: Format
        public var outputPath: Swift.String

        public init(
            workspacePath: Swift.String = "",
            changed: Swift.Bool = false,
            packagePaths: [Swift.String] = [],
            engines: [Swift.String] = [],
            jobs: Swift.Int? = nil,
            format: Format = .human,
            outputPath: Swift.String = ""
        ) {
            self.workspacePath = workspacePath
            self.changed = changed
            self.packagePaths = packagePaths
            self.engines = engines
            self.jobs = jobs
            self.format = format
            self.outputPath = outputPath
        }

        public static var configuration: Command.Configuration {
            .init(name: "measure", abstract: "Measure source without building or testing.")
        }

        public static var schema: Command.Schema.Definition<Self> {
            .init {
                Command.Option(\.workspacePath, name: .long(.literal("workspace-path")), placeholder: "workspace.xcworkspace")
                Command.Flag(\.changed, name: .long(.literal("changed")))
                Command.Option<Self, Swift.String>.Many(\.packagePaths, name: .long(.literal("package-path")), placeholder: "member")
                Command.Option<Self, Swift.String>.Many(\.engines, name: .long(.literal("engine")), placeholder: "engine")
                Command.Option(\.jobs, name: .long(.literal("jobs")), placeholder: "positive-count")
                Command.Option(\.format, name: .long(.literal("format")), placeholder: "human|json")
                Command.Option(\.outputPath, name: .long(.literal("output-path")), placeholder: "report")
            }
        }

        public mutating func validate() throws(Command.Error) {
            guard !workspacePath.isEmpty else { throw .validationFailed(reason: "--workspace-path is required") }
            guard !changed || packagePaths.isEmpty else { throw .validationFailed(reason: "--changed and --package-path are mutually exclusive") }
            guard jobs.map({ $0 > 0 }) ?? true else { throw .validationFailed(reason: "--jobs must be positive") }
            guard Set(packagePaths).count == packagePaths.count else { throw .validationFailed(reason: "duplicate --package-path") }
            guard Set(engines).count == engines.count else { throw .validationFailed(reason: "duplicate --engine") }
        }

        public mutating func run() async throws(Institute.Error) {
            let context = try Institute.Source.Command.context(workspace: workspacePath)
            let selection = changed
                ? await context.cohort.changed(jobs: jobs)
                : .init(
                    rows: try Institute.Source.Command.rows(
                        at: packagePaths,
                        in: context.cohort
                    ) ?? context.cohort.admitted,
                    reasons: []
                )
            let selected = changed || !packagePaths.isEmpty ? selection.rows : nil
            let selectedEngines = engines.isEmpty ? nil : Set(engines.map(SourceDomain.Engine.ID.init))
            let report = try await Institute.Source.Application().measure(
                cohort: context.cohort,
                selected: selected,
                engines: selectedEngines,
                jobs: jobs,
                references: selection.reasons,
                preparation: try Institute.Source.Command.preparation(workspace: workspacePath)
            )
            try Institute.Source.Command.write(
                report,
                format: format,
                to: outputPath
            )
            let unmeasured = !report.references.isEmpty || report.measurements.contains {
                if case .unmeasured = $0.verdict { true } else { false }
            }
            let findings = report.measurements.contains {
                if case .findings = $0.verdict { true } else { false }
            }
            Process.Exit.normal(unmeasured ? 2 : findings ? 1 : 0)
        }
    }
}

extension Institute.Source.Command.Measure {
    public enum Format: Swift.String, Sendable, Argument.Codable {
        case human
        case json

        public init?(argument: Swift.String) { self.init(rawValue: argument) }
        public var argumentDescription: Swift.String { rawValue }
    }
}

private typealias SourceDomain = Source
