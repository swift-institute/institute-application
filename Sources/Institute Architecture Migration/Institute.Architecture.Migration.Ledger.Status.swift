public import Institute_Architecture_Model
public import Institute_Model
public import JSON

extension Institute.Architecture.Migration.Ledger {
  public enum Status: Swift.String, Sendable, Equatable, JSON.Serializable {
    case pending
    case ready
    case blocked
    case passed
    case failed
    case published

    public static func serialize(_ value: Self) -> JSON { value.rawValue.json }

    public static func deserialize(_ json: JSON) throws(JSON.Error) -> Self {
      let rawValue = try Swift.String(json: json)
      guard let value = Self(rawValue: rawValue) else {
        throw .typeMismatch(expected: "migration ledger status", got: rawValue)
      }
      return value
    }
  }
}
