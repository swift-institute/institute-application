public import Institute_Model
public import JSON

extension Institute.Architecture.Migration.Ledger.Repository {
  public struct Seal: Sendable, Equatable {
    public let archived: Swift.Bool
    public let coordinate: Swift.String
    public let defaultBranch: Swift.String
    public let disabled: Swift.Bool
    public let head: Swift.String
    public let remote: Swift.String
    public let repositoryID: Swift.Int
    public let visibility: Swift.String

    public init(
      archived: Swift.Bool,
      coordinate: Swift.String,
      defaultBranch: Swift.String,
      disabled: Swift.Bool,
      head: Swift.String,
      remote: Swift.String,
      repositoryID: Swift.Int,
      visibility: Swift.String
    ) {
      self.archived = archived
      self.coordinate = coordinate
      self.defaultBranch = defaultBranch
      self.disabled = disabled
      self.head = head
      self.remote = remote
      self.repositoryID = repositoryID
      self.visibility = visibility
    }
  }
}

extension Institute.Architecture.Migration.Ledger.Repository.Seal: JSON.Serializable {
  public static func serialize(_ value: Self) -> JSON {
    [
      "archived": value.archived.json,
      "coordinate": value.coordinate.json,
      "defaultBranch": value.defaultBranch.json,
      "disabled": value.disabled.json,
      "head": value.head.json,
      "remote": value.remote.json,
      "repositoryID": value.repositoryID.json,
      "visibility": value.visibility.json,
    ]
  }

  public static func deserialize(_ json: JSON) throws(JSON.Error) -> Self {
    guard let object = json.dictionary else {
      throw .typeMismatch(expected: "repository migration seal", got: "non-object")
    }
    func value(_ key: Swift.String) throws(JSON.Error) -> JSON {
      guard let value = object[key] else { throw .missingKey(key) }
      return value
    }
    return try .init(
      archived: Swift.Bool(json: value("archived")),
      coordinate: Swift.String(json: value("coordinate")),
      defaultBranch: Swift.String(json: value("defaultBranch")),
      disabled: Swift.Bool(json: value("disabled")),
      head: Swift.String(json: value("head")),
      remote: Swift.String(json: value("remote")),
      repositoryID: Swift.Int(json: value("repositoryID")),
      visibility: Swift.String(json: value("visibility"))
    )
  }
}
