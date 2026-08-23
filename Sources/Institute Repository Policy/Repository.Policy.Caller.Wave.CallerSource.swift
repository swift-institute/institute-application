import Institute_Repository_Policy
import Foundation

extension Repository.Policy.Caller.Wave {
    public struct CallerSource: Codable, Sendable, Equatable {
        public let blob: String
        public let bytes: Data

        public init(blob: String, bytes: Data) {
            self.blob = blob
            self.bytes = bytes
        }
    }
}
