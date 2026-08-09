import Command
import Testing

@testable import Institute_Application
@testable import Institute_Model
@testable import Institute_Inventory
@testable import Institute_Dependency
@testable import Institute_Development
@testable import Institute_Lint
@testable import Institute_Pages
@testable import Institute_Doctor
@testable import Institute_Conversion
@testable import Institute_Instruments
@testable import Institute_GitHub

@Suite
struct `Institute Application CLI GitHub Tests` {

    // The minting mechanism itself lives in swift-github as the 'GitHub App'
    // product (TX-APP1A) and is tested there; what remains here is the CLI
    // surface that composes it.

    @Test
    func `accepts github token with an organization`() throws {
        var cli = Institute.Application.CLI(operation: .github, modes: [.token], organization: "swift-primitives")
        try cli.validate()
    }

    @Test
    func `requires an organization for github token`() {
        var cli = Institute.Application.CLI(operation: .github, modes: [.token])
        #expect(throws: Command.Error.self) { try cli.validate() }
    }

    @Test
    func `requires the token mode after github`() {
        var cli = Institute.Application.CLI(operation: .github, modes: [], organization: "swift-primitives")
        #expect(throws: Command.Error.self) { try cli.validate() }
    }

    @Test
    func `rejects credential flags outside github token`() {
        // A credential flag silently ignored mints a *wider* token than the
        // caller asked for, and nothing downstream can tell the difference.
        var narrowed = Institute.Application.CLI(operation: .doctor, permissions: ["contents=read"])
        #expect(throws: Command.Error.self) { try narrowed.validate() }
        var scoped = Institute.Application.CLI(operation: .sync, organization: "swift-primitives")
        #expect(throws: Command.Error.self) { try scoped.validate() }
    }
}
