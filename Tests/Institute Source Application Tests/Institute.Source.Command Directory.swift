import Foundation

/// A uniquely named temporary directory for one test, removed by the caller.
struct SourceCommandDirectory {
    let url: URL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

    func create() throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func remove() { try? FileManager.default.removeItem(at: url) }

    func path(of name: Swift.String) -> Swift.String {
        url.appending(path: name).path
    }
}
