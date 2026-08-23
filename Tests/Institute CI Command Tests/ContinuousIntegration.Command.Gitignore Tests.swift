import Foundation
import ContinuousIntegration
import Institute_Application_Foundation_Integration
import Testing

@testable import Institute_CI_Validation

extension ContinuousIntegration.Command.Gitignore {
    @Suite
    struct Test {
        static var root: URL {
            var root = URL(filePath: #filePath)
            root.deleteLastPathComponent()
            root.deleteLastPathComponent()
            root.deleteLastPathComponent()
            return root
        }

        static var canon: String {
            let path = root.appending(path: "canon/gitignore-package.txt")
            return String(decoding: FileManager.default.contents(atPath: path.path)!, as: UTF8.self)
        }

        static var fixtures: String {
            root.appending(path: "Tests/Institute Continuous Integration Validation Tests/Fixtures")
                .path
        }

        /// The Gitignore validator evaluates the fixture subjects through Git.
        /// The shared corpus is already inside this checkout's worktree, but
        /// the command integration test must not concurrently use that
        /// mutable repository state with the validation-corpus suite. Copy
        /// its data to a private root and give every selected subject an
        /// independent index before the harness sees it.
        static func withPrivateFixtures<Result>(
            _ body: (String) throws -> Result
        ) throws -> Result {
            let fileManager = FileManager.default
            let source = URL(filePath: fixtures)
            let root = fileManager.temporaryDirectory
                .appending(path: "institute-ci-command-gitignore-\(UUID().uuidString)")
            try fileManager.copyItem(at: source, to: root)
            do {
                try prepareRepositories(in: root)
                let result = try body(root.path)
                try fileManager.removeItem(at: root)
                return result
            } catch {
                // swift-linter:disable:next try optional
                // REASON: FileManager exposes untyped cleanup failure; the
                // original setup or assertion failure remains the verdict.
                try? fileManager.removeItem(at: root)
                throw error
            }
        }

        private static func prepareRepositories(in corpus: URL) throws {
            let fileManager = FileManager.default
            let ruleDirectories = try fileManager.contentsOfDirectory(
                at: corpus,
                includingPropertiesForKeys: [.isDirectoryKey]
            )
            .filter { $0.lastPathComponent.hasPrefix("gh-ignore-") }
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            for rule in ruleDirectories {
                for expectation in ["pass", "fail", "edge"] {
                    let root = rule.appending(path: expectation)
                    guard fileManager.fileExists(atPath: root.path) else { continue }
                    for subject in try fileManager.contentsOfDirectory(
                        at: root,
                        includingPropertiesForKeys: [.isDirectoryKey]
                    )
                    where (try? subject.resourceValues(forKeys: [.isDirectoryKey]).isDirectory)
                        == true
                    {
                        guard
                            try ContinuousIntegration.Validation.Gitignore.git(
                                ["init", "-q", "."],
                                in: subject,
                                input: nil
                            ).status == 0
                        else { throw CocoaError(.fileWriteUnknown) }
                        guard
                            try ContinuousIntegration.Validation.Gitignore.git(
                                ["add", "-f", "--all"],
                                in: subject,
                                input: nil
                            ).status == 0
                        else { throw CocoaError(.fileWriteUnknown) }
                    }
                }
            }
        }

        @Suite
        struct Unit {
            @Test func `render command parses exact policy inputs`() throws {
                #expect(
                    try ContinuousIntegration.Command.Gitignore.parse([
                        "render-gitignore", "--canon", "canon.txt", "--target", ".gitignore",
                    ]) == .render(canon: "canon.txt", target: ".gitignore")
                )
            }

            @Test func `validator command parses repository inputs`() throws {
                #expect(
                    try ContinuousIntegration.Command.Gitignore.parse([
                        "validate-gitignore", "--repository",
                        "swift-primitives/swift-byte-primitives",
                        "--root", "/tmp/subject", "--canon", "/tmp/canon.txt",
                    ])
                        == .validate(
                            repository: "swift-primitives/swift-byte-primitives",
                            root: "/tmp/subject",
                            canon: "/tmp/canon.txt"
                        )
                )
            }

            @Test func `renderer emits only complete canonical bytes`() throws {
                let rendered = try ContinuousIntegration.Command.Gitignore.render(
                    canon: ContinuousIntegration.Command.Gitignore.Test.canon,
                    target: "# tail\n"
                )
                #expect(rendered == ContinuousIntegration.Command.Gitignore.Test.canon)
                #expect(!rendered.contains("# tail"))
            }
        }

        @Suite
        struct `Edge Case` {
            @Test func `malformed command refuses before evaluation`() {
                #expect(
                    throws: ContinuousIntegration.Command.Gitignore.Error
                        .missingRequiredArgument("--root")
                ) {
                    _ = try ContinuousIntegration.Command.Gitignore.parse([
                        "validate-gitignore", "--repository",
                        "swift-primitives/swift-byte-primitives",
                    ])
                }
            }
        }

        @Suite
        struct Integration {
            @Test func `fixture controls self fire through an isolated copied harness`() throws {
                let marker = "gh-ignore-001/fail/drifted-header/.command-test-private"
                let shared = ContinuousIntegration.Command.Gitignore.Test.fixtures
                try ContinuousIntegration.Command.Gitignore.Test.withPrivateFixtures {
                    corpus in
                    let privateMarker = URL(filePath: corpus).appending(path: marker)
                    try Data("private\n".utf8).write(to: privateMarker)
                    #expect(corpus != shared)
                    #expect(!FileManager.default.fileExists(atPath: shared + "/" + marker))

                    let report = try ContinuousIntegration.Command.Gitignore.fixtures(
                        corpus: corpus
                    )
                    #expect(report.isComplete)
                    #expect(!report.outcomes.isEmpty)
                    #expect(
                        report.outcomes.contains {
                            $0.scenario.expectation == .violating && !$0.findings.isEmpty
                        }
                    )
                }
            }
        }
    }
}
