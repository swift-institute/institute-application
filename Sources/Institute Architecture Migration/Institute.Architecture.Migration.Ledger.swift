public import Institute_Architecture_Model
public import Institute_Model
public import JSON

extension Institute.Architecture.Migration {
  /// Durable state for the mechanical cutover and later package dispositions.
  public struct Ledger: Sendable, Equatable, JSON.Serializable {
    public let version: Swift.Int
    public let inventoryCommit: Swift.String
    public let organizations: [Organization]
    public let repositories: [Repository]
    public let decompositionQueue: [Swift.String]

    public init(
      version: Swift.Int,
      inventoryCommit: Swift.String,
      organizations: [Organization],
      repositories: [Repository],
      decompositionQueue: [Swift.String]
    ) {
      self.version = version
      self.inventoryCommit = inventoryCommit
      self.organizations = organizations
      self.repositories = repositories
      self.decompositionQueue = decompositionQueue
    }

    public static func serialize(_ value: Self) -> JSON {
      [
        "decompositionQueue": value.decompositionQueue.json,
        "inventoryCommit": value.inventoryCommit.json,
        "organizations": value.organizations.json,
        "repositories": value.repositories.json,
        "version": value.version.json,
      ]
    }

    public static func deserialize(_ json: JSON) throws(JSON.Error) -> Self {
      guard let object = json.dictionary else {
        throw .typeMismatch(expected: "migration ledger", got: "non-object")
      }
      guard let decompositionQueue = object["decompositionQueue"] else {
        throw .missingKey("decompositionQueue")
      }
      guard let inventoryCommit = object["inventoryCommit"] else {
        throw .missingKey("inventoryCommit")
      }
      guard let organizations = object["organizations"] else {
        throw .missingKey("organizations")
      }
      guard let repositories = object["repositories"] else {
        throw .missingKey("repositories")
      }
      guard let version = object["version"] else { throw .missingKey("version") }
      return try .init(
        version: Swift.Int(json: version),
        inventoryCommit: Swift.String(json: inventoryCommit),
        organizations: [Organization](json: organizations),
        repositories: [Repository](json: repositories),
        decompositionQueue: [Swift.String](json: decompositionQueue)
      )
    }
  }
}
