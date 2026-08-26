public import Institute_Architecture_Model
public import Institute_Model
public import JSON

extension Institute.Architecture.Migration.Ledger {
  public struct Result: Sendable, Equatable, JSON.Serializable {
    public let status: Status
    public let records: [Swift.String]

    public init(status: Status, records: [Swift.String] = []) {
      self.status = status
      self.records = records
    }

    public static func serialize(_ value: Self) -> JSON {
      ["records": value.records.json, "status": value.status.json]
    }

    public static func deserialize(_ json: JSON) throws(JSON.Error) -> Self {
      guard let object = json.dictionary else {
        throw .typeMismatch(expected: "migration result", got: "non-object")
      }
      guard let records = object["records"] else { throw .missingKey("records") }
      guard let status = object["status"] else { throw .missingKey("status") }
      return try .init(status: Status(json: status), records: [Swift.String](json: records))
    }
  }
}
