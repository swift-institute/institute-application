import Institute_Repository_Policy
import Foundation

extension RepositoryPolicy.Fleet {
    public static func read(at path: Swift.String) throws(Error) -> Self {
        let data: Data
        do {
            data = try Data(contentsOf: URL(filePath: path))
        } catch {
            throw .unreadable
        }
        let fleet: Self
        do {
            fleet = try JSONDecoder().decode(Self.self, from: data)
        } catch {
            throw .invalid
        }
        try fleet.validate()
        return fleet
    }
}
