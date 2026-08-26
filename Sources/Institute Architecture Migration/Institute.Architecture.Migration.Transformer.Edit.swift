public import Institute_Architecture_Model
public import Institute_Model

extension Institute.Architecture.Migration.Transformer {
  public struct Edit: Sendable, Equatable {
    public let currentPath: Swift.String
    public let futurePath: Swift.String
    public let currentText: Swift.String?
    public let futureText: Swift.String?

    public init(
      currentPath: Swift.String,
      futurePath: Swift.String,
      currentText: Swift.String?,
      futureText: Swift.String?
    ) {
      self.currentPath = currentPath
      self.futurePath = futurePath
      self.currentText = currentText
      self.futureText = futureText
    }

    public var changesPath: Swift.Bool { currentPath != futurePath }
    public var changesText: Swift.Bool { currentText != futureText }
  }
}
