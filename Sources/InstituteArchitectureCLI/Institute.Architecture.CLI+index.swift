private import InstituteArchitectureFacts
private import InstituteArchitectureGraph
private import InstituteArchitectureIndex
public import InstituteArchitectureModel
private import InstituteArchitectureValidation
public import Institute_Model

extension Institute.Architecture.CLI {
  /// Emits the complete, validated, versioned Architecture Index artifact.
  public static func index(
    path: Swift.String,
    report: (Swift.String) -> Swift.Void = { Swift.print($0) }
  ) throws(Error) -> Swift.Int32 {
    let root = try checkout(containing: path)
    let derived: Institute.Architecture.Facts
    do throws(Institute.Architecture.Facts.Error) {
      derived = try .derive(at: root)
    } catch {
      throw .derivation("\(error)")
    }
    let validation = Institute.Architecture.Validator().validate(
      derived: derived,
      today: today()
    )
    do throws(Institute.Architecture.Index.Artifact.Error) {
      let artifact = try Institute.Architecture.Index.Artifact(
        facts: derived,
        validation: validation
      )
      report(artifact.rendered)
    } catch {
      throw .artifact(error)
    }
    return 0
  }
}
