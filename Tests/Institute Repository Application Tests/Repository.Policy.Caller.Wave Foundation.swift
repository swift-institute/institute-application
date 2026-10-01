import Byte
import Foundation

enum CallerWaveFoundation {
    static func fixturePath(forResource name: String, withExtension ext: String) -> String? {
        Bundle.module.url(forResource: name, withExtension: ext)?.path
    }

    static func jsonBytes(withJSONObject object: Any) throws -> [Byte] {
        try JSONSerialization.data(withJSONObject: object).map { Byte(bitPattern: $0) }
    }

    static func sortedKeysJSONBytes(withJSONObject object: Any) throws -> [Byte] {
        try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]).map { Byte(bitPattern: $0) }
    }

    static func decode<T: Decodable>(_ type: T.Type, fromJSONObject object: Any) throws -> T {
        try JSONDecoder().decode(type, from: JSONSerialization.data(withJSONObject: object))
    }
}
