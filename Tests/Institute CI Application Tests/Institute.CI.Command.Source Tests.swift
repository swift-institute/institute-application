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
