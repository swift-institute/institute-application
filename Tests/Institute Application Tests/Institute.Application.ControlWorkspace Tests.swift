import Foundation
import Testing

/// The committed two-member control workspace is a build instrument: it opens
/// exactly this package and the institute domain package beside it, and
/// nothing else. Membership is asserted byte-for-byte — a control workspace
/// that silently gains or loses a member changes what "control-plane green"
/// measures.
@Suite
struct `Institute Control Workspace Membership` {
    @Test
    func `control workspace declares exactly the application and domain members`() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // Institute Application Tests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // repository root
        let workspace =
            root
            .appendingPathComponent("institute control.xcworkspace")
            .appendingPathComponent("contents.xcworkspacedata")
        let content = try String(contentsOf: workspace, encoding: .utf8)
        let expected = """
            <?xml version="1.0" encoding="UTF-8"?>
            <Workspace
               version = "1.0">
               <FileRef
                  location = "group:.">
               </FileRef>
               <FileRef
                  location = "group:../institute">
               </FileRef>
            </Workspace>

            """
        #expect(content == expected)
    }
}
