import Command
import Foundation
import Institute_Model
import Institute_Source
import Source_Repair
import Testing

@testable import Institute_Source_Application

@Test
func `source prepare defaults to the published linter and accepts an explicit local executable`() throws {
    let published = try Command.parse(
        Institute.Source.Command.Prepare.self,
        from: [
            "--workspace-path", "/workspace/institute interim.xcworkspace",
        ],
        initial: .init()
    )
    let local = try Command.parse(
        Institute.Source.Command.Prepare.self,
        from: [
            "--workspace-path", "/workspace/institute interim.xcworkspace",
            "--linter-executable", "/tmp/swift-linter-local",
        ],
        initial: .init()
    )

    #expect(published.linterExecutable == nil)
    #expect(local.linterExecutable == "/tmp/swift-linter-local")
}

@Test
func `source repair plan parses its typed grammar`() throws {
    let command = try Command.parse(
        Institute.Source.Command.Repair.Plan.self,
        from: [
            "--workspace-path", "/workspace/institute interim.xcworkspace",
            "--package-path", "/workspace/swift-one",
            "--package-path", "/workspace/swift-two",
            "--rule", "swift-linter:institute.forbidden-header",
            "--output-path", "/tmp/source-repair.json",
        ],
        initial: .init()
    )

    #expect(command.workspacePath == "/workspace/institute interim.xcworkspace")
    #expect(command.packagePaths == ["/workspace/swift-one", "/workspace/swift-two"])
    #expect(command.rules == ["swift-linter:institute.forbidden-header"])
    #expect(command.outputPath == "/tmp/source-repair.json")
}

@Test
func `source repair plan rejects changed and explicit package scope`() {
    #expect(throws: Command.Error.self) {
        _ = try Command.parse(
            Institute.Source.Command.Repair.Plan.self,
            from: [
                "--workspace-path", "/workspace/institute interim.xcworkspace",
                "--changed",
                "--package-path", "/workspace/swift-one",
                "--output-path", "/tmp/source-repair.json",
            ],
            initial: .init()
        )
    }
}

@Test
func `source rule selection requires exact engine and rule identity`() throws {
    guard
        let rules = try Institute.Source.Command.rules([
            "swift-format:formatting",
            "swift-linter:institute.forbidden-header",
        ])
    else {
        Issue.record("Expected explicit source rules")
        return
    }

    #expect(rules.count == 2)
    #expect(rules.map(\.engine.token).sorted() == ["swift-format", "swift-linter"])
    #expect(throws: Institute.Error.self) {
        _ = try Institute.Source.Command.rules(["missing-separator"])
    }
}

@Test
func `repair artifact replacement is bound to the same workspace cohort and subjects`() throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let path = directory.appending(path: "repair.json").path
    let first = repairPlan(subject: "swift-primitives/swift-one")
    let other = repairPlan(subject: "swift-primitives/swift-two")

    try Institute.Source.Command.write(first, to: path)
    try Institute.Source.Command.write(first, to: path)

    #expect(throws: Institute.Error.self) {
        try Institute.Source.Command.write(other, to: path)
    }
}

private func repairPlan(subject: Swift.String) -> Institute.Source.Repair.Plan {
    let repair = Source.Repair.Plan(
        subject: .init(identity: subject, digest: "subject"),
        profile: .init("profile"),
        sources: .init("sources"),
        operations: [],
        refusals: [],
        postconditions: []
    )
    return .init(
        workspace: "/workspace/institute interim.xcworkspace",
        workspaceDigest: "workspace",
        inventoryDigest: "inventory",
        cohort: ["swift-primitives/swift-one", "swift-primitives/swift-two"],
        repairs: [repair]
    )
}
