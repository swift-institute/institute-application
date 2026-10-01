import Foundation

enum ArtifactFoundation {
    static func replacingOccurrences(
        in text: Swift.String,
        of target: Swift.String,
        with replacement: Swift.String
    ) -> Swift.String {
        text.replacingOccurrences(of: target, with: replacement)
    }
}
