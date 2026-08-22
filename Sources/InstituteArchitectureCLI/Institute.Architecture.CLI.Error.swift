public import InstituteArchitectureIndex
public import InstituteArchitectureModel
public import Institute_Model

extension Institute.Architecture.CLI {
  /// Why `institute architecture validate` or `institute architecture
  /// index` could not complete.
  public enum Error: Swift.Error, Sendable, Equatable {
    case configuration(Swift.String)
    case noInstituteCheckout(searchedFrom: Swift.String)
    case derivation(Swift.String)
    case unstableIndex(first: Swift.String, second: Swift.String)
    case artifact(Institute.Architecture.Index.Artifact.Error)
  }
}
