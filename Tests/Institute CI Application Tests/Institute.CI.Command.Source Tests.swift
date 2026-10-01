import Command
import Source_Report
import Testing

@testable import Institute_CI_Application

@Test
func `CI source parses one exact package subject`() throws {
    let command = try Command.parse(
        Institute.CI.Command.Source.self,
        from: [
            "--repository", "swift-standards/swift-iso-639",
            "--revision", String(repeating: "a", count: 40),
            "--root", "/work/swift-iso-639",
            "--bundle", "standards",
            "--xcode-application", "/Applications/Xcode_27.0.app",
            "--jobs", "3",
        ],
        initial: .init()
    )

    #expect(command.repository == "swift-standards/swift-iso-639")
    #expect(command.revision == String(repeating: "a", count: 40))
    #expect(command.root == "/work/swift-iso-639")
    #expect(command.bundle == "standards")
    #expect(command.xcodeApplication == "/Applications/Xcode_27.0.app")
    #expect(command.jobs == 3)
}

@Test(arguments: [
    [
        "--repository", "swift-standards/swift-iso-639",
        "--revision", "not-a-commit",
        "--root", "/work/swift-iso-639",
        "--bundle", "standards",
        "--xcode-application", "/Applications/Xcode_27.0.app",
    ],
    [
        "--repository", "swift-standards/swift-iso-639",
        "--revision", String(repeating: "a", count: 40),
        "--root", "/work/swift-iso-639",
        "--bundle", "standards",
        "--xcode-application", "/tmp/Xcode.app",
    ],
    [
        "--repository", "swift-standards/swift-iso-639",
        "--revision", String(repeating: "a", count: 40),
        "--root", "/work/swift-iso-639",
        "--bundle", "unknown",
        "--xcode-application", "/Applications/Xcode_27.0.app",
    ],
    [
        "--repository", "swift-standards/swift-iso-639",
        "--revision", String(repeating: "a", count: 40),
        "--root", "relative/swift-iso-639",
        "--bundle", "standards",
        "--xcode-application", "/Applications/Xcode_27.0.app",
    ],
])
func `CI source refuses inexact policy inputs`(_ arguments: [String]) {
    #expect(throws: Command.Error.self) {
        _ = try Command.parse(
            Institute.CI.Command.Source.self,
            from: arguments,
            initial: .init()
        )
    }
}

@Test
func `CI source exit policy defaults to advisory and parses strict`() throws {
    let base = [
        "--repository", "swift-standards/swift-iso-639",
        "--revision", String(repeating: "a", count: 40),
        "--root", "/work/swift-iso-639",
        "--bundle", "standards",
        "--xcode-application", "/Applications/Xcode_27.0.app",
    ]
    let advisory = try Command.parse(Institute.CI.Command.Source.self, from: base, initial: .init())
    let strict = try Command.parse(
        Institute.CI.Command.Source.self,
        from: base + ["--exit-policy", "strict"],
        initial: .init()
    )

    #expect(advisory.exitPolicy == "advisory")
    #expect(strict.exitPolicy == "strict")
    #expect(throws: Command.Error.self) {
        _ = try Command.parse(
            Institute.CI.Command.Source.self,
            from: base + ["--exit-policy", "lenient"],
            initial: .init()
        )
    }
}

@Test
func `CI source exit policy fails only strict runs with error findings`() {
    let advisory = Institute.CI.Command.Source.Policy.advisory
    let strict = Institute.CI.Command.Source.Policy.strict

    #expect(advisory.code(status: .clean, errors: false) == 0)
    #expect(advisory.code(status: .findings, errors: true) == 0)
    #expect(advisory.code(status: .unmeasured, errors: false) == 2)
    #expect(strict.code(status: .clean, errors: false) == 0)
    #expect(strict.code(status: .findings, errors: false) == 0)
    #expect(strict.code(status: .findings, errors: true) == 1)
    #expect(strict.code(status: .unmeasured, errors: true) == 2)
}

/// Real `Source.Report` values for the exit policy's error classification:
/// one report per evidence channel, built through the report's own
/// initializers and classified by the production `errors(in:)` and
/// `Status(_:expected:)`. These reports carry an empty commitment, so
/// production classification reads them as unmeasured; that precedence is
/// asserted for both policies. A measured-status outcome needs a report
/// that `Source.Report.Complete` accepts, which these do not construct.
private enum PolicyReport {
    static let digest = String(repeating: "0", count: 64)
    static let engine = Source.Engine.ID("swift-format")
    static let rule = Source.Rule.ID(engine: engine, token: "AlwaysUseLowerCamelCase")
    static let subject = Source.Subject(
        identity: "swift-standards/swift-iso-639",
        root: "/work/swift-iso-639",
        artifacts: []
    )
    static let artifact = Source.Artifact(
        path: ".swift-format",
        kind: .configuration,
        purpose: .generatedPolicy,
        provenance: .authored,
        digest: .init(digest)
    )
    static let identity = Source.Artifact.Identity(
        digest: .init(digest),
        schema: .init("swift-format")
    )
    static let commitment = Source.Report.Commitment(
        subjects: [],
        engines: [],
        rules: [],
        requirements: [],
        predicates: [],
        predicateRequirements: []
    )

    static func finding(_ severity: Diagnostic.Severity) -> Source.Finding {
        .init(
            rule: rule,
            diagnostic: .init(
                location: .init(fileID: "ISO639.swift", line: 1, column: 1),
                severity: severity,
                identifier: rule.token,
                message: "fixture finding"
            ),
            repair: .automatic
        )
    }

    static func report(
        measurement: Source.Measurement.Verdict = .clean,
        artifact: Source.Artifact.Verdict? = nil,
        control: Source.Artifact.Verdict? = nil
    ) -> Source.Report {
        .init(
            scope: .workspace,
            profile: .init(digest),
            commitment: commitment,
            subjects: [subject],
            references: [],
            measurements: [
                .init(
                    engine: engine,
                    subject: subject,
                    activeRules: [rule],
                    applicableRules: [rule],
                    files: ["ISO639.swift"],
                    verdict: measurement
                )
            ],
            artifactEvidence: artifact.map {
                [
                    .init(
                        subject: subject.identity,
                        artifact: PolicyReport.artifact,
                        predicate: rule,
                        actual: identity,
                        expected: identity,
                        verdict: $0
                    )
                ]
            } ?? [],
            controlEvidence: control.map {
                [
                    .init(
                        identity: "fixture-control",
                        rule: rule,
                        expectation: .clean,
                        actualFindings: 1,
                        verdict: $0
                    )
                ]
            } ?? []
        )
    }
}

@Test
func `CI source exit policy classifies errors from each real report channel`() {
    typealias Policy = Institute.CI.Command.Source.Policy
    let reason = Source.Reason(code: "fixture", detail: "fixture finding")

    #expect(!Policy.errors(in: PolicyReport.report()))
    #expect(Policy.errors(in: PolicyReport.report(measurement: .findings([PolicyReport.finding(.error)]))))
    #expect(!Policy.errors(in: PolicyReport.report(measurement: .findings([PolicyReport.finding(.warning)]))))
    #expect(Policy.errors(in: PolicyReport.report(artifact: .findings([reason]))))
    #expect(!Policy.errors(in: PolicyReport.report(artifact: .clean)))
    #expect(Policy.errors(in: PolicyReport.report(control: .findings([reason]))))
    #expect(!Policy.errors(in: PolicyReport.report(control: .clean)))
}

@Test
func `CI source exit policy keeps an unmeasured real report at two under both policies`() {
    typealias Policy = Institute.CI.Command.Source.Policy
    let report = PolicyReport.report(measurement: .findings([PolicyReport.finding(.error)]))
    let status = Source.Report.Status(report, expected: report.commitment)

    #expect(status == .unmeasured)
    #expect(Policy.errors(in: report))
    #expect(Policy.advisory.code(status: status, errors: Policy.errors(in: report)) == 2)
    #expect(Policy.strict.code(status: status, errors: Policy.errors(in: report)) == 2)
}

