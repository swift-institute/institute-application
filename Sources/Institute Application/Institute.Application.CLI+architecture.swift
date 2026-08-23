private import Institute_Architecture_CLI
internal import Institute_Architecture_Model
internal import Institute_Model
private import Process

extension Institute.Application.CLI {
  func architecture(
    mode: Mode?,
    path: Swift.String
  ) throws(Institute.Error) -> Swift.Never {
    let status: Swift.Int32
    do throws(Institute.Architecture.CLI.Error) {
      switch mode {
      case .validate:
        status = try Institute.Architecture.CLI.validate(
          path: path
        )

      case .index:
        status = try Institute.Architecture.CLI.index(
          path: path
        )

      default:
        throw .configuration("architecture operation must be validate or index")
      }
    } catch {
      throw .configuration(
        "architecture \(mode?.argumentDescription ?? "unknown"): \(error)"
      )
    }
    Process.Exit.normal(status)
  }
}
