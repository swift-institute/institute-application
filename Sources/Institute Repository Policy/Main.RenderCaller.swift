import Institute_Repository_Policy

extension Institute.Application.RepositoryPolicyCLI {
    /// `repository-policy render-caller [--form terminal]`
    ///
    /// The superseded `current` and `direct` forms still accept their former
    /// repository, layer, input, and private-closure arguments until their
    /// final migration consumer is deleted.
    ///
    /// Prints the deterministic host projection to stdout (F3; #366).
    static func renderCaller(_ arguments: [String]) throws(Error) {
        var repository: String?
        var layer: Repository.Policy.Caller.Layer?
        var inputs: [(key: String, value: String)] = []
        var form = "terminal"
        var privateClosure = false
        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--repository": repository = iterator.next()

            case "--layer":
                guard let raw = iterator.next(),
                    let value = Repository.Policy.Caller.Layer(rawValue: raw)
                else {
                    throw .configuration(
                        RepositoryPolicy.ConfigurationError(
                            "--layer must be primitives|standards|institute"
                        )
                    )
                }
                layer = value

            case "--input":
                guard let raw = iterator.next(),
                    let separator = raw.firstIndex(of: "=")
                else {
                    throw .configuration(
                        RepositoryPolicy.ConfigurationError("--input needs <key>=<value>")
                    )
                }
                let key = String(raw[..<separator])
                guard Repository.Policy.Caller.approvedTypedInputs.contains(key) else {
                    throw .configuration(
                        RepositoryPolicy.ConfigurationError("unapproved input key \(key)")
                    )
                }
                inputs.append((key: key, value: String(raw[raw.index(after: separator)...])))

            case "--form":
                guard let value = iterator.next() else {
                    throw .configuration(
                        RepositoryPolicy.ConfigurationError("--form requires a value")
                    )
                }
                form = value

            case "--private-dependency-closure": privateClosure = true

            default:
                throw .configuration(
                    RepositoryPolicy.ConfigurationError(
                        "unknown render-caller argument \(argument)"
                    )
                )
            }
        }
        if form == "terminal" {
            print(Repository.Policy.Caller.Render.terminal, terminator: "")
            return
        }
        guard let repository, let layer else {
            throw .configuration(
                RepositoryPolicy.ConfigurationError(
                    "render-caller --form \(form) requires --repository and --layer"
                )
            )
        }
        let caller: Repository.Policy.Caller
        do throws(Repository.Policy.Caller.Error) {
            caller = try Repository.Policy.Caller(
                repository: repository,
                layer: layer,
                inputs: inputs
            )
        } catch {
            throw .caller(error)
        }
        switch form {
        case "current":
            print(Repository.Policy.Caller.Render.current(caller), terminator: "")

        case "direct":
            print(
                Repository.Policy.Caller.Render.direct(
                    caller,
                    privateDependencyClosure: privateClosure
                ),
                terminator: ""
            )

        default:
            throw .configuration(
                RepositoryPolicy.ConfigurationError(
                    "--form must be current|direct|terminal"
                )
            )
        }
    }
}
