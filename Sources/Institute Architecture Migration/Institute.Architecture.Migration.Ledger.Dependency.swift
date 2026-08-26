public import Institute_Architecture_Model
public import Institute_Model
public import JSON

extension Institute.Architecture.Migration.Ledger {
  public struct Dependency: Sendable, Equatable, JSON.Serializable {
    public let manifest: Swift.String
    public let current: Swift.String
    public let future: Swift.String

    public init(manifest: Swift.String, current: Swift.String, future: Swift.String) {
      self.manifest = manifest
      self.current = current
      self.future = future
    }

    public static func serialize(_ value: Self) -> JSON {
      [
        "current": value.current.json,
        "future": value.future.json,
        "manifest": value.manifest.json,
      ]
    }

    public static func deserialize(_ json: JSON) throws(JSON.Error) -> Self {
      guard let object = json.dictionary else {
        throw .typeMismatch(expected: "dependency migration", got: "non-object")
      }
      guard let current = object["current"] else { throw .missingKey("current") }
      guard let future = object["future"] else { throw .missingKey("future") }
      guard let manifest = object["manifest"] else { throw .missingKey("manifest") }
      return try .init(
        manifest: Swift.String(json: manifest),
        current: Swift.String(json: current),
        future: Swift.String(json: future)
      )
    }
  }
}
