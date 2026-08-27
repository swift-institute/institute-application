public import Institute_Architecture_Model
public import Institute_Model
public import JSON

extension Institute.Architecture.Migration.Ledger {
  public struct Repository: Sendable, Equatable, JSON.Serializable {
    public let current: Swift.String
    public let future: Swift.String
    public let currentLayer: Swift.String
    public let futureLayer: Swift.String
    public let expectedCommit: Swift.String?
    public let expectedCommitSource: Swift.String
    public let observedHead: Swift.String?
    public let observedRemote: Swift.String?
    public let dirtyPaths: [Swift.String]
    public let dependencies: [Dependency]
    public let state: Status
    public let preparation: Result
    public let validation: Result
    public let publication: Result
    public let disposition: Result
    public let seal: Seal?

    public init(
      current: Swift.String,
      future: Swift.String,
      currentLayer: Swift.String,
      futureLayer: Swift.String,
      expectedCommit: Swift.String?,
      expectedCommitSource: Swift.String,
      observedHead: Swift.String?,
      observedRemote: Swift.String?,
      dirtyPaths: [Swift.String],
      dependencies: [Dependency],
      state: Status,
      preparation: Result,
      validation: Result,
      publication: Result,
      disposition: Result,
      seal: Seal? = nil
    ) {
      self.current = current
      self.future = future
      self.currentLayer = currentLayer
      self.futureLayer = futureLayer
      self.expectedCommit = expectedCommit
      self.expectedCommitSource = expectedCommitSource
      self.observedHead = observedHead
      self.observedRemote = observedRemote
      self.dirtyPaths = dirtyPaths
      self.dependencies = dependencies
      self.state = state
      self.preparation = preparation
      self.validation = validation
      self.publication = publication
      self.disposition = disposition
      self.seal = seal
    }

    public static func serialize(_ value: Self) -> JSON {
      [
        "current": value.current.json,
        "currentLayer": value.currentLayer.json,
        "dependencies": value.dependencies.json,
        "dirtyPaths": value.dirtyPaths.json,
        "disposition": value.disposition.json,
        "expectedCommit": value.expectedCommit?.json ?? .null,
        "expectedCommitSource": value.expectedCommitSource.json,
        "future": value.future.json,
        "futureLayer": value.futureLayer.json,
        "observedHead": value.observedHead?.json ?? .null,
        "observedRemote": value.observedRemote?.json ?? .null,
        "preparation": value.preparation.json,
        "publication": value.publication.json,
        "seal": value.seal?.json ?? .null,
        "state": value.state.json,
        "validation": value.validation.json,
      ]
    }

    public static func deserialize(_ json: JSON) throws(JSON.Error) -> Self {
      guard let object = json.dictionary else {
        throw .typeMismatch(expected: "repository migration", got: "non-object")
      }
      func value(_ key: Swift.String) throws(JSON.Error) -> JSON {
        guard let value = object[key] else { throw .missingKey(key) }
        return value
      }
      let expected = try value("expectedCommit")
      let head = try value("observedHead")
      let remote = try value("observedRemote")
      let seal: Seal?
      if let value = object["seal"], !value.isNull {
        seal = try Seal(json: value)
      } else {
        seal = nil
      }
      return try .init(
        current: Swift.String(json: value("current")),
        future: Swift.String(json: value("future")),
        currentLayer: Swift.String(json: value("currentLayer")),
        futureLayer: Swift.String(json: value("futureLayer")),
        expectedCommit: expected.isNull ? nil : Swift.String(json: expected),
        expectedCommitSource: Swift.String(json: value("expectedCommitSource")),
        observedHead: head.isNull ? nil : Swift.String(json: head),
        observedRemote: remote.isNull ? nil : Swift.String(json: remote),
        dirtyPaths: [Swift.String](json: value("dirtyPaths")),
        dependencies: [Dependency](json: value("dependencies")),
        state: Status(json: value("state")),
        preparation: Result(json: value("preparation")),
        validation: Result(json: value("validation")),
        publication: Result(json: value("publication")),
        disposition: Result(json: value("disposition")),
        seal: seal
      )
    }
  }
}
