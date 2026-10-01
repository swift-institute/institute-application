import Byte
import Foundation

enum UniformityWaveFoundation {
    static func fixturePath(forResource name: String, withExtension ext: String) -> String? {
        Bundle.module.url(forResource: name, withExtension: ext)?.path
    }

    static func sortedKeysJSONBytes(withJSONObject object: Any) throws -> [Byte] {
        [Byte](try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]))
    }

    static func decode<T: Decodable>(_ type: T.Type, fromJSONObject object: Any) throws -> T {
        try JSONDecoder().decode(type, from: JSONSerialization.data(withJSONObject: object))
    }
}
