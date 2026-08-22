import InstituteArchitectureModel
import Institute_Model

extension Institute.Architecture.Exemption.Expiry {
    /// A canonical `YYYY-MM-DD` literal, for fixtures whose validity is
    /// established by inspection at the call site.
    ///
    /// Traps rather than throwing, so a fixture can be a stored constant in a
    /// non-throwing context. A trap here is a defect in the literal, not a
    /// runtime condition under test.
    internal static func fixture(_ rawValue: Swift.String) -> Self {
        do throws(Institute.Architecture.Exemption.Error) {
            return try Self(rawValue: rawValue)
        } catch {
            Swift.preconditionFailure("malformed fixture expiry '\(rawValue)': \(error)")
        }
    }
}
