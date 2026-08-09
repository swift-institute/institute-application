internal import Institute_Model

private import InstituteArchitectureCLI
private import InstituteArchitectureModel
private import Process

// The architecture surface is invoked from its own file because
// `InstituteArchitectureModel` declares its own `Institute` namespace. Before
// the target split the application's `Institute` was declared in this very
// module and therefore shadowed it; once the domain semantics moved to
// `Institute_Model`, both spellings arrived through imports and every bare
// `Institute` in a file importing both became ambiguous. Confining the
// architecture import to one file keeps every other file's `Institute`
// unambiguous, and this file writes the qualified form deliberately.
extension Institute_Model.Institute.Application.CLI {
    func architecture(
        mode: Mode?,
        path: Swift.String
    ) throws(Institute_Model.Institute.Error) -> Swift.Never {
        let status: Swift.Int32
        do throws(InstituteArchitectureModel.Institute.Architecture.CLI.Error) {
            switch mode {
            case .validate:
                status = try InstituteArchitectureModel.Institute.Architecture.CLI.validate(
                    path: path
                )
            case .index:
                status = try InstituteArchitectureModel.Institute.Architecture.CLI.index(
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
