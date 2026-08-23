public import Institute_Model
import Institute_Repository_Policy
import Byte_Primitives
import Byte_Primitives_Standard_Library_Integration
import Foundation
import Institute_CI_Application
import Testing

@Suite
struct `Repository Policy BrokenSymlink Tests` {
    @Test
    func `only missing targets are findings`() throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let target = root.appending(path: "target")
        #expect(FileManager.default.createFile(atPath: target.path, contents: Data()))
        try FileManager.default.createSymbolicLink(
            at: root.appending(path: "live"),
            withDestinationURL: target
        )
        try FileManager.default.createSymbolicLink(
            atPath: root.appending(path: "broken").path,
            withDestinationPath: "missing"
        )

        let findings = try Institute.Repository.Policy.BrokenSymlink.findings(at: root.path)

        #expect(findings == [.init(path: "broken")])
    }
}
