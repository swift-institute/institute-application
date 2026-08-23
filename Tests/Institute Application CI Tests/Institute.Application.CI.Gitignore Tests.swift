public import Institute_Model
import Institute_Application_Model
import Institute_Application_CI
import Institute_CI_Model
import Testing

@testable import Institute_CI_Canon

// The corpus-harness integration coverage for the gitignore rules lives
// with the corpus itself, in the institute package's CI Validation test
// suite; this suite owns only the command family's argument grammar and
// rendering seam.
extension Institute.Application.CI.Gitignore {
    @Suite
    struct Test {
        static let terminator = Institute.CI.Canon.Gitignore.terminator
        static let canon =
            "# CANONICAL\n/*\n!/Sources/\n"
            + Institute.CI.Canon.Gitignore.Capability.block
            + "\(terminator)\n"

        @Suite
        struct Unit {
            @Test func `render command parses exact policy inputs`() throws {
                #expect(
                    try Institute.Application.CI.Gitignore.parse([
                        "render-gitignore", "--canon", "canon.txt", "--target", ".gitignore",
                    ]) == .render(canon: "canon.txt", target: ".gitignore")
                )
            }

            @Test func `validator command parses repository inputs`() throws {
                #expect(
                    try Institute.Application.CI.Gitignore.parse([
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
                let rendered = try Institute.Application.CI.Gitignore.render(
                    canon: Institute.Application.CI.Gitignore.Test.canon,
                    target: "# tail\n"
                )
                #expect(rendered == Institute.Application.CI.Gitignore.Test.canon)
                #expect(!rendered.contains("# tail"))
            }
        }

        @Suite
        struct `Edge Case` {
            @Test func `malformed command refuses before evaluation`() {
                #expect(
                    throws: Institute.Application.CI.Gitignore.Error
                        .missingRequiredArgument("--root")
                ) {
                    _ = try Institute.Application.CI.Gitignore.parse([
                        "validate-gitignore", "--repository",
                        "swift-primitives/swift-byte-primitives",
                    ])
                }
            }
        }
    }
}
