import Command
import Institute_Application_Lint
import Institute_Application_Package
import Institute_Application_Workspace
import Institute_Model
import Institute_Lint
import Testing

@testable import Institute_Application

/// Parses one argv through the typed router, exactly as `main.swift` does.
private func parse(
    _ argv: [Swift.String]
) throws -> Institute.Application.CLI {
    try Command.parse(Institute.Application.CLI.self, from: argv, initial: .sync(.init()))
}

extension Institute.Application.CLI.Test {
    @Suite struct Lint {}
}

extension Institute.Application.CLI.Test.Lint {
    /// The sweep takes no mode. `institute lint` is the ecosystem run;
    /// the tool operations are named.
    @Test
    func `a bare lint is the ecosystem sweep`() throws {
        let command = try parse(["lint"])
        guard case .lint(let lint) = command else {
            Issue.record("expected lint, got \(command)")
            return
        }
        #expect(lint.modes.isEmpty)
        #expect(!lint.changed)
    }

    @Test(arguments: [
        ("install", Institute.Lint.Command.Mode.install),
        ("check", Institute.Lint.Command.Mode.check),
    ])
    func `lint parses its tool operations`(
        argument: Swift.String,
        expected: Institute.Lint.Command.Mode
    ) throws {
        let command = try parse(["lint", argument])
        guard case .lint(let lint) = command else {
            Issue.record("expected lint, got \(command)")
            return
        }
        #expect(lint.modes == [expected])
    }

    @Test
    func `ledger accepts deterministic output and supplied coordinates`() throws {
        let revision = Swift.String(repeating: "a", count: 40)
        let command = try parse([
            "lint", "ledger",
            "--format", "json",
            "--disposition", "PLAT-ARCH-022=remediation@swift-foundations/swift-linter#20",
            "--verification",
            "swift-primitives/swift-bytes@\(revision)="
                + "https://github.com/swift-primitives/swift-bytes/actions/runs/42",
        ])

        guard case .lint(let lint) = command else {
            Issue.record("expected lint, got \(command)")
            return
        }
        #expect(lint.modes == [.ledger])
        #expect(lint.output == "json")
        #expect(lint.dispositions.count == 1)
        #expect(lint.verifications.count == 1)
    }

    @Test(arguments: [
        ["lint", "ledger", "--changed"],
        ["lint", "ledger", "--fix"],
        ["lint", "ledger", "--dry-run"],
        ["lint", "ledger", "--disposition", "not-a-coordinate"],
        ["lint", "ledger", "--verification", "not-a-coordinate"],
        ["lint", "--format", "json"],
        ["doctor", "--disposition", "RULE=remediation@owner/repository#1"],
    ])
    func `ledger rejects narrowing mutation and misplaced inputs`(arguments: [Swift.String]) {
        #expect(throws: Command.Error.self) {
            _ = try parse(arguments)
        }
    }

    @Test
    func `ledger rejects duplicate rule ownership before measuring`() {
        #expect(throws: Command.Error.self) {
            _ = try parse([
                "lint", "ledger",
                "--disposition", "RULE=retention@owner/repository#1",
                "--disposition", "RULE=remediation@owner/repository#2",
            ])
        }
    }

    @Test
    func `the sweep accepts a changed scope`() throws {
        let command = try parse(["lint", "--changed"])
        guard case .lint(let lint) = command else {
            Issue.record("expected lint, got \(command)")
            return
        }
        #expect(lint.changed)
    }

    /// The inner-loop verb, alongside `package build` and `package
    /// test`. Mirroring the existing shape is what makes it findable
    /// without being told.
    @Test
    func `package lint parses`() throws {
        let command = try parse(["package", "lint"])
        guard case .package(.lint) = command else {
            Issue.record("expected package lint, got \(command)")
            return
        }
    }

    @Test
    func `package lint takes no fresh scratch`() {
        #expect(throws: Command.Error.self) {
            _ = try parse(["package", "lint", "--fresh"])
        }
    }

    /// The local CI-parity gate: same package-scoped shape as `package
    /// lint`, alongside `package build` and `package test`.
    @Test
    func `package check parses`() throws {
        let command = try parse(["package", "check"])
        guard case .package(.check) = command else {
            Issue.record("expected package check, got \(command)")
            return
        }
    }

    /// Unlike `package lint`, `check` runs a build and a test step, so
    /// `--fresh` (fresh scratch state) is meaningful here — the evidence
    /// run the contribution workflow asks for before opening a PR.
    @Test
    func `package check accepts fresh scratch`() throws {
        let command = try parse(["package", "check", "--fresh"])
        guard case .package(.check(let check)) = command else {
            Issue.record("expected package check, got \(command)")
            return
        }
        #expect(check.fresh)
    }

    /// `--changed` on a single package would read as a filter and do
    /// nothing. A flag that silently has no effect is worse than one
    /// that is rejected.
    @Test(arguments: [
        ["package", "lint", "--changed"],
        ["lint", "check", "--changed"],
        ["doctor", "--changed"],
        ["sync", "--changed"],
    ])
    func `changed belongs to the sweep alone`(argument: [Swift.String]) {
        #expect(throws: Command.Error.self) {
            _ = try parse(argument)
        }
    }

    @Test(arguments: [
        ["lint", "serve"],
        ["lint", "build"],
        ["lint", "--package-path", "/tmp"],
        ["lint", "--consumer", "a", "--dependency", "b"],
        ["lint", "--dry-run"],
    ])
    func `lint rejects options that belong elsewhere`(argument: [Swift.String]) {
        #expect(throws: Command.Error.self) {
            _ = try parse(argument)
        }
    }
}

extension Institute.Application.CLI.Test.Lint {
    @Test
    func `the sweep accepts a fix request`() throws {
        let command = try parse(["lint", "--fix"])
        guard case .lint(let lint) = command else {
            Issue.record("expected lint, got \(command)")
            return
        }
        #expect(lint.fix)
        #expect(!lint.dry)
    }

    /// `--dry-run` is otherwise rejected here; with `--fix` it is the
    /// preview of the rewrite, which is the one plan a lint run has to show.
    @Test
    func `a fix accepts a dry run`() throws {
        let command = try parse(["lint", "--fix", "--dry-run"])
        guard case .lint(let lint) = command else {
            Issue.record("expected lint, got \(command)")
            return
        }
        #expect(lint.fix)
        #expect(lint.dry)
    }

    @Test
    func `a dry run without a fix is still rejected`() {
        #expect(throws: (any Swift.Error).self) {
            _ = try parse(["lint", "--dry-run"])
        }
    }

    /// A fix is a rewrite, and the operations that cannot rewrite must say
    /// so rather than drop the flag — a silently ignored `--fix` leaves the
    /// caller reading findings and believing they are a repair record.
    @Test
    func `a fix outside lint is rejected`() {
        #expect(throws: (any Swift.Error).self) {
            _ = try parse(["doctor", "--fix"])
        }
    }

    @Test
    func `package lint accepts a fix`() throws {
        let command = try parse(["package", "lint", "--fix"])
        guard case .package(.lint(let lint)) = command else {
            Issue.record("expected package lint, got \(command)")
            return
        }
        #expect(lint.fix)
    }
}
