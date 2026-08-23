import Command
import Institute_Instruments
import Institute_Model
import Testing

@testable import Institute_Application_Foundation_Integration

extension Institute.Application.CLI.Test.Unit {
    @Test
    func `certification assemble parses receipt and evidence`() throws {
        let command = try Command.parse(
            Institute.Application.CLI.self,
            from: [
                "certification", "assemble",
                "--receipt", "snapshot.json",
                "--evidence", "evidence.jsonl",
            ],
            initial: .init()
        )

        #expect(command.operation == .certification)
        #expect(command.modes == [.assemble])
        #expect(command.receiptPath == "snapshot.json")
        #expect(command.evidencePath == "evidence.jsonl")
    }

    @Test
    func `evidence parses mixed account and coverage lines`() throws {
        let text = """
            {"obligation":{"key":"swift-primitives/swift-byte-primitives",\
            "kind":"build","platform":"macos"},"outcome":{"met":"local run"}}

            {"consumer":"swift-primitives/swift-byte-primitives","proofs":[]}
            """

        let evidence = try Institute.Application.CLI.Evidence.parse(text)

        #expect(evidence.accounts.count == 1)
        #expect(evidence.accounts.first?.outcome == .met(evidence: "local run"))
        #expect(evidence.coverage.count == 1)
        #expect(
            evidence.coverage.first?.consumer.identity
                == "swift-primitives/swift-byte-primitives"
        )
        #expect(evidence.replacedCoverage == 0)
    }

    @Test
    func `evidence keeps the last coverage for a repeated consumer`() throws {
        let text = """
            {"consumer":"swift-primitives/swift-byte-primitives","proofs":[]}
            {"consumer":"swift-primitives/swift-byte-primitives","proofs":[\
            {"consumer":"swift-primitives/swift-byte-primitives",\
            "location":"https://github.com/swift-primitives/swift-index-primitives.git",\
            "verdict":{"exact":"swift-primitives/swift-index-primitives"}}]}
            """

        let evidence = try Institute.Application.CLI.Evidence.parse(text)

        #expect(evidence.coverage.count == 1)
        #expect(evidence.coverage.first?.proofs.count == 1)
        #expect(evidence.replacedCoverage == 1)
    }
}

extension Institute.Application.CLI.Test.`Edge Case` {
    @Test
    func `certification assemble refuses a missing evidence path`() throws {
        #expect(throws: Command.Error.self) {
            try Command.parse(
                Institute.Application.CLI.self,
                from: ["certification", "assemble", "--receipt", "snapshot.json"],
                initial: .init()
            )
        }
    }

    @Test
    func `certification run refuses an evidence path`() throws {
        #expect(throws: Command.Error.self) {
            try Command.parse(
                Institute.Application.CLI.self,
                from: [
                    "certification", "run",
                    "--receipt", "snapshot.json",
                    "--evidence", "evidence.jsonl",
                ],
                initial: .init()
            )
        }
    }

    @Test
    func `evidence refuses a line that is neither record kind`() throws {
        let text = """
            {"consumer":"swift-primitives/swift-byte-primitives","proofs":[]}
            {"unexpected":"record"}
            """

        do throws(Institute.Error) {
            _ = try Institute.Application.CLI.Evidence.parse(text)
            Issue.record("a line that parses as neither record kind must be refused")
        } catch {
            #expect("\(error)".contains("line 2"))
        }
    }

    @Test
    func `evidence refuses a non-JSON line by number`() throws {
        let text = """
            {"consumer":"swift-primitives/swift-byte-primitives","proofs":[]}
            {"consumer":"swift-primitives/swift-index-primitives","proofs":[]}
            not json at all
            """

        do throws(Institute.Error) {
            _ = try Institute.Application.CLI.Evidence.parse(text)
            Issue.record("a non-JSON evidence line must be refused")
        } catch {
            #expect("\(error)".contains("line 3"))
        }
    }

    @Test
    func `evidence refuses a duplicate account for one obligation`() throws {
        let account = """
            {"obligation":{"key":"swift-primitives/swift-byte-primitives",\
            "kind":"build","platform":"macos"},"outcome":{"met":"local run"}}
            """
        let text = "\(account)\n\(account)"

        do throws(Institute.Error) {
            _ = try Institute.Application.CLI.Evidence.parse(text)
            Issue.record("a duplicate account for one obligation must be refused")
        } catch {
            #expect("\(error)".contains("line 2"))
            #expect("\(error)".contains("swift-primitives/swift-byte-primitives"))
        }
    }
}
