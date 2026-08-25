import Command
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
