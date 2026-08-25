public import Command
public import Command_Schema
public import Institute_Model
public import Institute_CI_Model
public import Institute_Source
public import Institute_Source_Workspace
public import JSON
public import Source_Report
import Console
import Process

extension Institute.CI.Command {
    public struct Source: Sendable, Command_Schema.Command.`Protocol` {
        public var repository: Swift.String
        public var revision: Swift.String
        public var root: Swift.String
        public var bundle: Swift.String
        public var xcodeApplication: Swift.String
        public var jobs: Swift.Int?

        public init(
            repository: Swift.String = "",
            revision: Swift.String = "",
            root: Swift.String = "",
            bundle: Swift.String = "",
            xcodeApplication: Swift.String = "",
            jobs: Swift.Int? = nil
        ) {
            self.repository = repository
            self.revision = revision
            self.root = root
            self.bundle = bundle
            self.xcodeApplication = xcodeApplication
            self.jobs = jobs
        }

        public static var configuration: Command_Schema.Command.Configuration {
            .init(name: "source", abstract: "Measure one checked-out package source subject.")
        }

        public static var schema: Command_Schema.Command.Schema.Definition<Self> {
            .init {
                Command_Schema.Command.Option(
                    \.repository,
                    name: .long(.literal("repository")),
                    placeholder: "owner/name"
                )
                Command_Schema.Command.Option(
                    \.revision,
                    name: .long(.literal("revision")),
                    placeholder: "commit"
                )
                Command_Schema.Command.Option(
                    \.root,
                    name: .long(.literal("root")),
                    placeholder: "package-root"
                )
                Command_Schema.Command.Option(
                    \.bundle,
                    name: .long(.literal("bundle")),
                    placeholder: "primitives|standards|institute"
                )
                Command_Schema.Command.Option(
                    \.xcodeApplication,
                    name: .long(.literal("xcode-application")),
                    placeholder: "/Applications/Xcode.app"
                )
                Command_Schema.Command.Option(
                    \.jobs,
                    name: .long(.literal("jobs")),
                    placeholder: "positive-count"
                )
            }
        }

        public mutating func validate() throws(Command_Schema.Command.Error) {
            let repositoryComponents = repository.split(
                separator: "/",
                omittingEmptySubsequences: false
            )
            guard repositoryComponents.count == 2,
                repositoryComponents.allSatisfy({ !$0.isEmpty })
            else {
                throw .validationFailed(reason: "--repository must be owner/name")
            }
            guard revision.utf8.count == 40,
                revision.utf8.allSatisfy({
                    ($0 >= 48 && $0 <= 57) || ($0 >= 97 && $0 <= 102)
                })
            else {
                throw .validationFailed(
                    reason: "--revision must be an exact lowercase 40-character commit"
                )
            }
            guard root.hasPrefix("/") else {
                throw .validationFailed(reason: "--root must be an absolute package path")
            }
            guard Institute.Source.Bundle(rawValue: bundle) != nil else {
                throw .validationFailed(
                    reason: "--bundle must be primitives, standards, or institute"
                )
            }
            guard xcodeApplication.hasPrefix("/Applications/"),
                xcodeApplication.hasSuffix(".app")
            else {
                throw .validationFailed(
                    reason: "--xcode-application must name an application under /Applications"
                )
            }
            guard jobs.map({ $0 > 0 }) ?? true else {
                throw .validationFailed(reason: "--jobs must be positive")
            }
        }

        public mutating func run() async throws(Institute.Error) {
            let bundle = try Institute.Source.Application.bundle(bundle)
            let subject = try Institute.Source.Workspace.subject(
                repository: repository,
                revision: revision,
                root: root
            )
            let application = Institute.Source.Application()
            let preparation = try await application.prepare(
                subject: subject,
                xcodeApplication: xcodeApplication
            )
            let measured = try await application.measure(
                subject: subject,
                bundle: bundle,
                jobs: jobs,
                preparation: preparation
            )
            let bytes = measured.jsonString(sortKeys: true)
            let report: Source_Report.Source.Report
            do throws(JSON.Error) {
                report = try .init(jsonString: bytes)
            } catch {
                throw .configuration("source report serialization did not parse: \(error)")
            }
            print(bytes)
            Process.Exit.normal(
                Source_Report.Source.Report.Status(report, expected: report.commitment).code
            )
        }
    }

    static func source(_ arguments: [Swift.String]) async {
        var command: Source
        do throws(Command_Schema.Command.Error) {
            command = try Command_Schema.Command.parse(
                Source.self,
                from: arguments,
                initial: .init()
            )
        } catch {
            Console.Output.error("institute ci source: \(error)")
            terminate(64)
        }
        do throws(Institute.Error) {
            try await command.run()
        } catch {
            Console.Output.error("institute ci source: \(error)")
            terminate(2)
        }
    }
}
