public import Institute_Instruments
public import Institute_Model
public import JSON

extension Institute.Certification.Command {
    /// The typed content of one captured certification evidence file: the
    /// JSONL stream `certification run` prints — one account or one closure
    /// coverage per line — read back for `certification assemble`.
    ///
    /// Parsing is fail-closed: a line that is neither a valid account nor a
    /// valid closure coverage is a typed error naming its line number, never
    /// a silent skip. A later coverage line for a consumer replaces the
    /// earlier one — re-evaluated members supersede their first record — and
    /// every replacement is counted so assembly can report it. A second
    /// account for the same obligation is refused here, where the diagnostic
    /// can still name the line, rather than at certificate construction.
    public struct Evidence: Equatable, Sendable {
        /// Every parsed account, in first-appearance order.
        public let accounts: [Institute.Certification.Account]

        /// One coverage record per consumer, in first-appearance order;
        /// where a consumer appeared more than once, the last record.
        public let coverage: [Institute.Certification.Closure.Coverage]

        /// How many coverage lines were replaced by a later line for the
        /// same consumer.
        public let replacedCoverage: Swift.Int

        public init(
            accounts: [Institute.Certification.Account],
            coverage: [Institute.Certification.Closure.Coverage],
            replacedCoverage: Swift.Int
        ) {
            self.accounts = accounts
            self.coverage = coverage
            self.replacedCoverage = replacedCoverage
        }
    }
}

extension Institute.Certification.Command.Evidence {
    /// Parses one evidence file's text. Blank lines are file convention and
    /// carry no record; every other line must deserialize as exactly one
    /// account or one closure coverage.
    public static func parse(_ text: Swift.String) throws(Institute.Error) -> Self {
        var accounts = [Institute.Certification.Account]()
        var accountedObligations = Set<Institute.Certification.Obligation>()
        var coverage = [Institute.Certification.Closure.Coverage]()
        var coverageIndex = [Institute.Repository.Key: Swift.Int]()
        var replacedCoverage = 0

        var number = 0
        for slice in text.split(separator: "\n", omittingEmptySubsequences: false) {
            number += 1
            let line = Swift.String(slice)
            guard !line.allSatisfy({ $0 == " " || $0 == "\t" || $0 == "\r" }) else {
                continue
            }
            let json: JSON
            do throws(JSON.Error) {
                json = try JSON.parse(line)
            } catch {
                throw .configuration(
                    "evidence line \(number) is not JSON: \(error)"
                )
            }
            guard let object = json.dictionary else {
                throw .configuration(
                    "evidence line \(number) is not a JSON object"
                )
            }
            if object["obligation"] != nil {
                let account: Institute.Certification.Account
                do throws(JSON.Error) {
                    account = try Institute.Certification.Account(json: json)
                } catch {
                    throw .configuration(
                        "evidence line \(number) is not a valid account: \(error)"
                    )
                }
                guard accountedObligations.insert(account.obligation).inserted else {
                    throw .configuration(
                        "evidence line \(number) accounts an obligation twice: "
                            + "\(account.obligation.key.identity) "
                            + "\(account.obligation.kind.rawValue) "
                            + account.obligation.platform.rawValue
                    )
                }
                accounts.append(account)
            } else if object["consumer"] != nil {
                let record: Institute.Certification.Closure.Coverage
                do throws(JSON.Error) {
                    record = try Institute.Certification.Closure.Coverage(json: json)
                } catch {
                    throw .configuration(
                        "evidence line \(number) is not a valid closure coverage: "
                            + "\(error)"
                    )
                }
                if let existing = coverageIndex[record.consumer] {
                    coverage[existing] = record
                    replacedCoverage += 1
                } else {
                    coverageIndex[record.consumer] = coverage.count
                    coverage.append(record)
                }
            } else {
                throw .configuration(
                    "evidence line \(number) is neither an account nor a closure "
                        + "coverage (keys: \(object.keys.sorted().joined(separator: ", ")))"
                )
            }
        }
        return .init(
            accounts: accounts,
            coverage: coverage,
            replacedCoverage: replacedCoverage
        )
    }
}
