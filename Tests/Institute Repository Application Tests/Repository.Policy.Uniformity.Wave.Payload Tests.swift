public import Institute_Model
import Institute_Repository_Policy
import Byte
import Byte_Standard_Library_Integration
import Foundation
import Testing

@testable import Institute_Repository_Application

/// Shape policy 5 measured the way git will measure it.
///
/// Reading the allowlist patterns and reasoning about them is how the
/// premise of the shim wave came to be wrong in the first place: policy 4
/// looked like it admitted `Sources/**` when its only re-inclusions were
/// `*.swift` and `*.docc/**`, so every C shim header a `* Shims` target
/// needs was silently untracked. These probes therefore materialise a
/// throwaway repository, hand git the embedded payload as its `.gitignore`,
/// and let `git add` decide — directory pruning and all — rather than
/// asserting over pattern text.
@Suite
struct `Repository Policy Uniformity Wave Payload Tests` {
    /// Paths a `* Shims` target needs, which policy 4 denied and policy 5
    /// must admit.
    private static let admitted = [
        "Sources/ARM Shims/shim.c",
        "Sources/CPU Shims/include/atomic.h",
        "Sources/Foo Shims/include/module.modulemap",
    ]

    /// Near misses that must stay denied. `CIEEE754` is not a `* Shims`
    /// directory despite starting with `C`; `Shims` alone has no space-
    /// separated prefix; `README.md` is not a shim source; `.cpp` is not
    /// one of the three admitted extensions.
    private static let denied = [
        "Sources/CIEEE754/x.c",
        "Sources/Foo Shims/README.md",
        "Sources/Shims/x.h",
        "Sources/Type Metadata Shims/T.cpp",
    ]

    @Test
    func policyFiveAdmitsShimSourcesAndStillDeniesTheirNearMisses() throws {
        let probes = Self.admitted + Self.denied
        let repository = GitProbeRepository()
        try repository.initialize()
        try repository.write(
            Institute.Repository.Policy.Uniformity.Wave.Payload.canonical(),
            to: ".gitignore"
        )
        for probe in probes {
            try repository.write([Byte]("probe\n".utf8), to: probe)
        }
        // A Swift source under an ordinary target is the positive control:
        // if it is missing from the tracked set the harness, not the
        // policy, is what failed.
        try repository.write([Byte]("// probe\n".utf8), to: "Sources/Foo/Foo.swift")

        try repository.run(["add", "-A"])
        let tracked = Set(try repository.trackedPaths())

        #expect(tracked.contains("Sources/Foo/Foo.swift"))
        #expect(tracked.contains(".gitignore"))
        for path in Self.admitted {
            #expect(tracked.contains(path), "policy 5 must admit \(path)")
        }
        for path in Self.denied {
            #expect(!tracked.contains(path), "policy 5 must deny \(path)")
        }
    }
}

/// A throwaway `git init` tree the shape policy can be measured in.
///
/// `Repository Policy Tests` cannot reach the validation module's
/// `git check-ignore` owner — that target is not among its dependencies
/// and the helper is internal to it — so this file carries the minimum
/// process transport the probe needs and nothing more.
private struct GitProbeRepository: ~Copyable {
    let root: URL

    /// Resolved eagerly but held optionally: a noncopyable type cannot be
    /// partially initialised, so a missing `git` becomes a typed failure at
    /// first use rather than a throwing initialiser.
    private let executable: URL?

    init() {
        self.executable = Self.gitExecutable()
        self.root = URL(filePath: NSTemporaryDirectory())
            .appending(path: "institute-ci-shape-policy")
            .appending(path: UUID().uuidString)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    /// Make the directory a repository. Separate from `init` for the reason
    /// above, and called once before any probe is written.
    func initialize() throws {
        try run(["init", "-q"])
    }

    func write(_ contents: [Byte], to relative: String) throws {
        let location = root.appending(path: relative)
        try FileManager.default.createDirectory(
            at: location.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(contents.underlying).write(to: location)
    }

    /// Stage-0 pathnames, NUL-delimited so a path containing a space or a
    /// quote is never re-encoded by git's path quoting.
    func trackedPaths() throws -> [String] {
        let output = try run(["ls-files", "-z"])
        return output.split(separator: 0).compactMap { String(data: Data($0), encoding: .utf8) }
    }

    @discardableResult
    func run(_ arguments: [String]) throws -> Data {
        guard let executable else { throw GitProbeFailure.gitUnavailable }
        let process = Process()
        let pipe = Pipe()
        process.executableURL = executable
        // Git's ambient control variables can redirect the repository,
        // index, and excludes; a fixed excludes file removes the one that
        // would silently change this measurement.
        process.arguments = ["-C", root.path, "-c", "core.excludesFile=/dev/null"] + arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try process.run()
        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw GitProbeFailure.gitFailed(arguments) }
        return output
    }

    private static func gitExecutable() -> URL? {
        #if os(Windows)
            let candidates = ["C:/Program Files/Git/cmd/git.exe"]
        #else
            let candidates = ["/usr/bin/git", "/usr/local/bin/git", "/opt/homebrew/bin/git"]
        #endif
        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate) {
            return URL(filePath: candidate)
        }
        guard let path = ProcessInfo.processInfo.environment["PATH"] else { return nil }
        #if os(Windows)
            let separator: Character = ";"
            let names = ["git.exe"]
        #else
            let separator: Character = ":"
            let names = ["git"]
        #endif
        for directory in path.split(separator: separator) {
            for name in names {
                let candidate = String(directory) + "/" + name
                if FileManager.default.isExecutableFile(atPath: candidate) {
                    return URL(filePath: candidate)
                }
            }
        }
        return nil
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }
}

private enum GitProbeFailure: Swift.Error {
    case gitUnavailable
    case gitFailed([String])
}
