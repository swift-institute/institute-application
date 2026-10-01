import Foundation

enum ControlWorkspaceFoundation {
    /// The committed control workspace's `contents.xcworkspacedata`, read as
    /// UTF-8 from the repository root three levels above `filePath`.
    static func contents(besideTestFile filePath: Swift.String) throws -> Swift.String {
        let root = URL(fileURLWithPath: filePath)
            .deletingLastPathComponent()  // Institute Application Tests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // repository root
        let workspace =
            root
            .appendingPathComponent("institute control.xcworkspace")
            .appendingPathComponent("contents.xcworkspacedata")
        return try String(contentsOf: workspace, encoding: .utf8)
    }
}
