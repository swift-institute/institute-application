import Institute_Repository_Policy
import Foundation

extension Repository.Policy.Uniformity.Wave.Recensus {
    public struct Evidence: Sendable {
        public let payload: Data
        public let receipts: [Repository.Policy.Uniformity.Wave.Receipt]
        public let events: [Repository.Policy.Uniformity.Wave.Event]
        public let closures: [Repository.Policy.Uniformity.Wave.Closure]
        public let policyDigest: String
        public let policySource: String

        public init(
            payload: Data,
            receipts: [Repository.Policy.Uniformity.Wave.Receipt],
            events: [Repository.Policy.Uniformity.Wave.Event],
            closures: [Repository.Policy.Uniformity.Wave.Closure],
            policyDigest: String,
            policySource: String
        ) {
            self.payload = payload
            self.receipts = receipts
            self.events = events
            self.closures = closures
            self.policyDigest = policyDigest
            self.policySource = policySource
        }
    }
}
