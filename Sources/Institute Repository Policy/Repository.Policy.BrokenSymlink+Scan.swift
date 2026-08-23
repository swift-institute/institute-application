import Institute_Repository_Policy
import Foundation

extension RepositoryPolicy.BrokenSymlink {
    /// Broken symbolic links beneath `root`, in repository-relative order.
    public static func findings(at root: String) throws(Error) -> [Finding] {
        let fileManager = FileManager.default
        let initial: [String]
        do {
            initial = try fileManager.contentsOfDirectory(atPath: root)
        } catch {
            throw .unreadableRoot(root)
        }

        var findings: [Finding] = []
        var pending = initial
        while let path = pending.popLast() {
            let absolute = root + "/" + path
            let attributes: [FileAttributeKey: Any]
            do {
                attributes = try fileManager.attributesOfItem(atPath: absolute)
            } catch {
                throw .unreadablePath(path)
            }
            guard attributes[.type] as? FileAttributeType == .typeSymbolicLink else {
                if attributes[.type] as? FileAttributeType == .typeDirectory {
                    let children: [String]
                    do {
                        children = try fileManager.contentsOfDirectory(atPath: absolute)
                    } catch {
                        throw .unreadablePath(path)
                    }
                    pending.append(contentsOf: children.map { path + "/" + $0 })
                }
                continue
            }
            if !fileManager.fileExists(atPath: absolute) {
                findings.append(.init(path: path))
            }
        }
        return findings.sorted { $0.path < $1.path }
    }
}
