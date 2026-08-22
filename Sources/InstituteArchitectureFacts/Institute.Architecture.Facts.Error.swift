public import InstituteArchitectureModel
public import Institute_Model

extension Institute.Architecture.Facts {
  /// Why derivation from disk failed.
  public enum Error: Swift.Error, Sendable, Equatable {
    case unreadableFile(path: Swift.String, reason: Swift.String)
    case undecodableInventory(Swift.String)
  }
}
