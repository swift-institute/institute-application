public import Institute_Model
public import Institute_Repository_Policy

extension Institute.Application.Repository {
    /// Every way one repository subcommand refuses, preserving the
    /// refusing domain's own typed error. `execute` renders whichever
    /// domain refused and exits non-zero.
    public enum Error: Swift.Error, CustomStringConvertible {
        case configuration(String)
        case client(Institute.Repository.Policy.Client.Error)
        case ruleset(Institute.Repository.Policy.Ruleset.Error)
        case census(Institute.Application.Repository.Census.Generator.Error)
        case metadata(Institute.Repository.Policy.Metadata.Error)
        case caller(Institute.Repository.Policy.Caller.Error)
        case wave(Institute.Repository.Policy.Caller.Wave.Error)
        case io(String)

        public var description: String {
            switch self {
            case .configuration(let message): return message
            case .client(let error): return error.description
            case .ruleset(let error): return error.description
            case .census(let error): return "\(error)"
            case .metadata(let error): return "\(error)"
            case .caller(let error): return "\(error)"
            case .wave(let error): return error.description
            case .io(let message): return message
            }
        }
    }
}
