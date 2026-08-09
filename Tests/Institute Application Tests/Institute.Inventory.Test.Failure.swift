@testable import Institute_Application

extension Institute.Inventory.Test {
    enum Failure: Swift.Error, Equatable, Sendable {
        case malformed
        case status
    }
}
