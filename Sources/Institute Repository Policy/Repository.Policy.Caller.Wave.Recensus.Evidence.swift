import Institute_Repository_Policy
import Foundation

extension Repository.Policy.Caller.Wave.Recensus {
    public struct Evidence: Sendable {
        public let caller: Data
        public let receipts: [Repository.Policy.Caller.Wave.Receipt]
        public let events: [Repository.Policy.Caller.Wave.Event]
        public let closures: [Repository.Policy.Caller.Wave.Closure]
        public let policyDigest: String
        public let policySource: String

        public init(
            caller: Data,
            receipts: [Repository.Policy.Caller.Wave.Receipt],
            events: [Repository.Policy.Caller.Wave.Event],
            closures: [Repository.Policy.Caller.Wave.Closure],
            policyDigest: String,
            policySource: String
        ) {
            self.caller = caller
            self.receipts = receipts
            self.events = events
            self.closures = closures
            self.policyDigest = policyDigest
            self.policySource = policySource
        }
    }
}
