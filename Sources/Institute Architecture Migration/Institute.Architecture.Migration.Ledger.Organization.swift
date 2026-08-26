public import Institute_Architecture_Model
public import Institute_Model
public import JSON

extension Institute.Architecture.Migration.Ledger {
  public struct Organization: Sendable, Equatable, JSON.Serializable {
    public let current: Swift.String
    public let future: Swift.String
    public let kind: Swift.String
    public let collisionCheck: Result
    public let publication: Result

    public init(
      current: Swift.String,
      future: Swift.String,
      kind: Swift.String,
      collisionCheck: Result,
      publication: Result
    ) {
      self.current = current
      self.future = future
      self.kind = kind
      self.collisionCheck = collisionCheck
      self.publication = publication
    }

    public static func serialize(_ value: Self) -> JSON {
      [
        "collisionCheck": value.collisionCheck.json,
        "current": value.current.json,
        "future": value.future.json,
        "kind": value.kind.json,
        "publication": value.publication.json,
      ]
    }

    public static func deserialize(_ json: JSON) throws(JSON.Error) -> Self {
      guard let object = json.dictionary else {
        throw .typeMismatch(expected: "organization migration", got: "non-object")
      }
      guard let collisionCheck = object["collisionCheck"] else {
        throw .missingKey("collisionCheck")
      }
      guard let current = object["current"] else { throw .missingKey("current") }
      guard let future = object["future"] else { throw .missingKey("future") }
      guard let kind = object["kind"] else { throw .missingKey("kind") }
      guard let publication = object["publication"] else {
        throw .missingKey("publication")
      }
      return try .init(
        current: Swift.String(json: current),
        future: Swift.String(json: future),
        kind: Swift.String(json: kind),
        collisionCheck: Result(json: collisionCheck),
        publication: Result(json: publication)
      )
    }
  }
}
