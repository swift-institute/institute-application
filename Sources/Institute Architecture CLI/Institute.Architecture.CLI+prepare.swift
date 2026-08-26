private import File_System
private import Git_Foundation
private import Institute_Architecture_Migration
public import Institute_Architecture_Model
public import Institute_Model
private import JSON
private import Process

extension Institute.Architecture.CLI {
  /// Plans or applies one exact-commit repository transformation.
  public static func prepare(
    ledgerPath: Swift.String,
    repository coordinate: Swift.String,
    repositoryPath: Swift.String,
    dryRun: Swift.Bool,
    report: (Swift.String) -> Swift.Void = { Swift.print($0) }
  ) throws(Error) -> Swift.Int32 {
    let ledgerSource = try text(at: ledgerPath)
    let ledger: Institute.Architecture.Migration.Ledger
    do throws(JSON.Error) {
      ledger = try .init(jsonString: ledgerSource)
    } catch {
      throw .ledger("cannot decode migration ledger \(ledgerPath): \(error)")
    }
    guard let record = ledger.repositories.first(where: { $0.current == coordinate }) else {
      throw .ledger("migration ledger has no repository \(coordinate)")
    }
    guard let expectedCommit = record.expectedCommit else {
      throw .ledger("migration ledger has no expected commit for \(coordinate)")
    }
    let directory: File.Directory
    do throws(File.Path.Error) {
      directory = try File.Directory(validating: repositoryPath)
    } catch {
      throw .ledger("invalid --repository-path \(repositoryPath): \(error)")
    }
    let git = Git.Client()
    let head: Swift.String
    let dirty: [Git.Status.Entry]
    do throws(Git.Client.Error) {
      head = try git.head(at: directory.description).rawValue
      dirty = try git.status(at: directory.description)
    } catch {
      throw .ledger("cannot inspect exact repository state at \(directory): \(error)")
    }
    guard head == expectedCommit else {
      throw .ledger(
        "expected \(coordinate) at \(expectedCommit), observed \(head)"
      )
    }
    guard dirty.isEmpty else {
      throw .ledger(
        "repository worktree is not clean: "
          + dirty.map { Swift.String(decoding: $0.path, as: Swift.UTF8.self) }
          .joined(separator: ", ")
      )
    }

    let paths = try trackedFiles(at: directory)
    var files: [Swift.String: Swift.String?] = [:]
    for path in paths {
      // The cutover control plane deliberately retains both sides of every rename.
      guard !cutoverControlPlane(path) else {
        files[path] = .some(nil)
        continue
      }
      guard textCandidate(path) else {
        files[path] = .some(nil)
        continue
      }
      let contents = try bytes(at: "\(directory)/\(path)")
      let text = Swift.String(decoding: contents, as: Swift.UTF8.self)
      guard Array(text.utf8) == contents else {
        files[path] = .some(nil)
        continue
      }
      files[path] = text
    }
    let transformer = Institute.Architecture.Migration.Transformer(ledger: ledger)
    let plan = transformer.plan(files: files)
    try validate(plan: plan, trackedPaths: paths, at: directory)
    let textEdits = plan.count { $0.changesText }
    let pathEdits = plan.count { $0.changesPath }
    report(
      "architecture prepare: \(coordinate) at \(expectedCommit); "
        + "\(textEdits) text edits, \(pathEdits) path edits"
    )
    for edit in plan where edit.changesPath {
      report("  move \(edit.currentPath) -> \(edit.futurePath)")
    }
    guard !dryRun else { return 0 }

    for edit in plan where edit.changesText {
      guard let futureText = edit.futureText else {
        throw .ledger("text edit lost its future contents at \(edit.currentPath)")
      }
      try write(futureText, at: "\(directory)/\(edit.currentPath)")
    }
    for edit in plan.filter(\.changesPath).sorted(by: {
      $0.currentPath.count > $1.currentPath.count
    }) {
      try move(edit, at: directory)
    }
    let changed: [Git.Status.Entry]
    do throws(Git.Client.Error) {
      changed = try git.status(at: directory.description)
    } catch {
      throw .ledger("cannot inspect prepared repository state: \(error)")
    }
    guard !plan.isEmpty || changed.isEmpty else {
      throw .ledger("empty transformation unexpectedly changed \(coordinate)")
    }
    report("architecture prepare: applied; git reports \(changed.count) changed paths")
    return 0
  }

  private static func validate(
    plan: [Institute.Architecture.Migration.Transformer.Edit],
    trackedPaths: [Swift.String],
    at directory: File.Directory
  ) throws(Error) {
    let destinations = plan.map(\.futurePath)
    guard Set(destinations).count == destinations.count else {
      throw .ledger("transformation contains colliding destination paths")
    }
    let moving = Set(plan.filter(\.changesPath).map(\.currentPath))
    let tracked = Set(trackedPaths)
    for edit in plan where edit.changesPath {
      if tracked.contains(edit.futurePath), !moving.contains(edit.futurePath) {
        throw .ledger(
          "destination path is already tracked: \(edit.currentPath) -> \(edit.futurePath)"
        )
      }
      if try exists("\(directory)/\(edit.futurePath)"), !moving.contains(edit.futurePath) {
        throw .ledger(
          "destination path is unexpectedly occupied: \(edit.currentPath) -> \(edit.futurePath)"
        )
      }
    }
  }

  private static func textCandidate(_ path: Swift.String) -> Swift.Bool {
    let name = path.split(separator: "/").last.map(Swift.String.init) ?? path
    if [
      "Package.swift", "README", "README.md", "LICENSE", "LICENSE.md", ".gitignore", "Dockerfile",
    ]
    .contains(name) {
      return true
    }
    return [
      ".swift", ".md", ".markdown", ".json", ".yaml", ".yml", ".txt", ".sh",
      ".zsh", ".toml", ".xcconfig", ".pbxproj", ".xcscheme", ".xml", ".plist",
      ".csv", ".tsv", ".html", ".css", ".js", ".ts",
    ].contains { name.hasSuffix($0) }
  }

  private static func cutoverControlPlane(_ path: Swift.String) -> Swift.Bool {
    path == "Migration.json"
      || path.hasPrefix("Sources/Institute Architecture Migration/")
      || path.hasPrefix(
        "Tests/Institute Architecture Tests/Institute.Architecture.Migration."
      )
  }

  private static func write(_ text: Swift.String, at path: Swift.String) throws(Error) {
    let file: File
    do throws(File.Path.Error) {
      file = try File(.init(path))
    } catch {
      throw .ledger("invalid prepared file path \(path): \(error)")
    }
    do throws(File.System.Write.Atomic.Error) {
      try file.write.atomic(text)
    } catch {
      throw .ledger("cannot write prepared file \(path): \(error)")
    }
  }

  private static func move(
    _ edit: Institute.Architecture.Migration.Transformer.Edit,
    at directory: File.Directory
  ) throws(Error) {
    if let separator = edit.futurePath.lastIndex(of: "/") {
      let parent = Swift.String(edit.futurePath[..<separator])
      try command(["mkdir", "-p", "\(directory)/\(parent)"], label: "create move destination")
    }
    try command(
      ["git", "-C", directory.description, "mv", "--", edit.currentPath, edit.futurePath],
      label: "move tracked path"
    )
  }

  private static func exists(_ path: Swift.String) throws(Error) -> Swift.Bool {
    let output: Process.Output
    do throws(Process.Error) {
      output = try Process.Spawn.run(
        .init(executable: "/usr/bin/test", arguments: ["-e", path])
      )
    } catch {
      throw .ledger("cannot inspect destination path \(path): \(error)")
    }
    switch output.status {
    case .exited(let code) where code == 0: return true
    case .exited(let code) where code == 1: return false
    default: throw .ledger("cannot inspect destination path \(path): \(output.status)")
    }
  }

  private static func command(_ arguments: [Swift.String], label: Swift.String) throws(Error) {
    let output: Process.Output
    do throws(Process.Error) {
      output = try Process.Spawn.run(
        .init(
          executable: "/usr/bin/env",
          arguments: arguments,
          stdout: .pipe,
          stderr: .pipe
        )
      )
    } catch {
      throw .ledger("\(label): \(error)")
    }
    guard case .exited(let code) = output.status, code == 0 else {
      throw .ledger(
        "\(label): " + Swift.String(decoding: output.stderr ?? [], as: Swift.UTF8.self)
      )
    }
  }
}
