public import Institute_Model
public import Institute_CI_Model
public import Institute_CI_Validation

extension Institute.Application.CI {
    /// Every way the CI command family refuses, preserving the refusing
    /// domain's own typed error.
    public enum Error: Swift.Error {
        case command(Institute.Application.CI.Gitignore.Error)
        case unreadable(String)
        case environment(Institute.CI.Validation.EnvironmentDefect)
        case unowned([String])
    }
}

extension Institute.Application.CI.Error {
    public var message: String {
        switch self {
        case .command(let error): error.message

        case .unreadable(let path): "could not read `\(path)`"

        case .environment(let error): error.message

        case .unowned(let directories):
            "unowned Gitignore fixture directories: \(directories.joined(separator: ", "))"
        }
    }
}
