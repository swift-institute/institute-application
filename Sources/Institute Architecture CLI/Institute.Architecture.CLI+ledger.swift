public import File_System
private import Git_Foundation
private import Institute_Architecture_Facts
private import Institute_Architecture_Migration
public import Institute_Architecture_Model
public import Institute_Model
private import JSON
private import Process

extension Institute.Architecture.CLI {
  /// Derives and atomically writes the initial four-layer migration ledger.
  public static func ledger(
    path: Swift.String,
    outputPath: Swift.String,
    report: (Swift.String) -> Swift.Void = { Swift.print($0) }
  ) throws(Error) -> Swift.Int32 {
    let checkout = try checkout(containing: path)
    let root: Institute.Root
    let configuration: Institute.Configuration
    do throws(Institute.Error) {
      root = try Institute.Root(checkout: checkout)
      configuration = try Institute.Configuration.load(at: root.checkout)
    } catch {
      throw .ledger("cannot load Institute control plane: \(error)")
    }

    let git = Git.Client()
    let inventoryCommit: Swift.String
    do throws(Git.Client.Error) {
      inventoryCommit = try git.head(at: root.checkout.description).rawValue
    } catch {
      throw .ledger("cannot bind Institute.json to its commit: \(error)")
    }

    let mapping = Institute.Architecture.Migration.Mapping()
    let organizations = mapping.organizationRenames.map {
      Institute.Architecture.Migration.Ledger.Organization(
        current: $0.current,
        future: $0.future,
        kind: $0.kind,
        collisionCheck: .init(
          status: .pending,
          records: ["live GitHub destination collision check required"]
        ),
        publication: .init(status: .pending)
      )
    }

    var repositories: [Institute.Architecture.Migration.Ledger.Repository] = []
    for repository in configuration.repositories {
      repositories.append(
        derive(
          repository: repository,
          root: root,
          git: git,
          mapping: mapping
        )
      )
    }
    repositories.sort { $0.current < $1.current }
    let queue =
      repositories
      .filter { $0.futureLayer == "molecules" }
      .map(\.future)
      .sorted()
    let ledger = Institute.Architecture.Migration.Ledger(
      version: 1,
      inventoryCommit: inventoryCommit,
      organizations: organizations,
      repositories: repositories,
      decompositionQueue: queue
    )
    let file: File
    do throws(File.Path.Error) {
      file = try File(.init(outputPath))
    } catch {
      throw .ledger("invalid --output-path \(outputPath): \(error)")
    }
    do throws(File.System.Write.Atomic.Error) {
      try file.write.atomic(ledger.jsonString(sortKeys: true) + "\n")
    } catch {
      throw .ledger("cannot write migration ledger \(file): \(error)")
    }
    let ready = repositories.count { $0.state == .ready }
    let blocked = repositories.count - ready
    report(
      "architecture ledger: \(repositories.count) repositories, \(ready) ready, "
        + "\(blocked) blocked; decomposition queue \(queue.count)"
    )
    return blocked == 0 ? 0 : 1
  }

  private static func derive(
    repository: Institute.Repository,
    root: Institute.Root,
    git: Git.Client,
    mapping: Institute.Architecture.Migration.Mapping
  ) -> Institute.Architecture.Migration.Ledger.Repository {
    let current = "\(repository.organization)/\(repository.name)"
    let future = mapping.coordinate(current)
    let directory: File.Directory
    do throws(Institute.Error) {
      directory = try root.materialization(for: repository)
    } catch {
      return unavailable(
        repository: repository,
        current: current,
        future: future,
        mapping: mapping,
        reason: "materialization path unavailable: \(error)"
      )
    }

    var failures: [Swift.String] = []
    let observedHead: Swift.String?
    do throws(Git.Client.Error) {
      observedHead = try git.head(at: directory.description).rawValue
    } catch {
      observedHead = nil
      failures.append("HEAD unavailable: \(error)")
    }
    let expectedCommit: Swift.String?
    do throws(Git.Client.Error) {
      expectedCommit = try git.head("refs/remotes/origin/main", at: directory.description)
        .rawValue
    } catch {
      expectedCommit = nil
      failures.append("origin/main unavailable: \(error)")
    }
    let observedRemote: Swift.String?
    do throws(Git.Client.Error) {
      observedRemote = try git.remote("origin", at: directory.description)
    } catch {
      observedRemote = nil
      failures.append("origin URL unavailable: \(error)")
    }
    let dirtyPaths: [Swift.String]
    do throws(Git.Client.Error) {
      dirtyPaths = try git.status(at: directory.description)
        .map { Swift.String(decoding: $0.path, as: Swift.UTF8.self) }
        .sorted()
    } catch {
      dirtyPaths = []
      failures.append("working state unavailable: \(error)")
    }
    if !dirtyPaths.isEmpty {
      failures.append("developer worktree is dirty; prepare from an isolated exact-commit worktree")
    }
    if observedHead != expectedCommit {
      failures.append("HEAD does not equal the locally recorded origin/main")
    }

    let dependencies: [Institute.Architecture.Migration.Ledger.Dependency]
    do throws(Error) {
      dependencies = try dependencyEdges(
        at: directory,
        mapping: mapping
      )
    } catch {
      dependencies = []
      failures.append("dependency scan unavailable: \(error)")
    }
    let state: Institute.Architecture.Migration.Ledger.Status = failures.isEmpty ? .ready : .blocked
    return .init(
      current: current,
      future: future,
      currentLayer: repository.layer.token,
      futureLayer: mapping.layer(repository.layer.token),
      expectedCommit: expectedCommit,
      expectedCommitSource: "local refs/remotes/origin/main; live verification pending",
      observedHead: observedHead,
      observedRemote: observedRemote,
      dirtyPaths: dirtyPaths,
      dependencies: dependencies,
      state: state,
      preparation: .init(status: .pending, records: failures),
      validation: .init(status: .pending),
      publication: .init(
        status: .pending,
        records: ["verify expected old commit with the publishing identity immediately before push"]
      ),
      disposition: .init(status: .pending)
    )
  }

  private static func unavailable(
    repository: Institute.Repository,
    current: Swift.String,
    future: Swift.String,
    mapping: Institute.Architecture.Migration.Mapping,
    reason: Swift.String
  ) -> Institute.Architecture.Migration.Ledger.Repository {
    .init(
      current: current,
      future: future,
      currentLayer: repository.layer.token,
      futureLayer: mapping.layer(repository.layer.token),
      expectedCommit: nil,
      expectedCommitSource: "unmeasured",
      observedHead: nil,
      observedRemote: nil,
      dirtyPaths: [],
      dependencies: [],
      state: .blocked,
      preparation: .init(status: .blocked, records: [reason]),
      validation: .init(status: .pending),
      publication: .init(status: .pending),
      disposition: .init(status: .pending)
    )
  }

  private static func dependencyEdges(
    at directory: File.Directory,
    mapping: Institute.Architecture.Migration.Mapping
  ) throws(Error) -> [Institute.Architecture.Migration.Ledger.Dependency] {
    var dependencies: [Institute.Architecture.Migration.Ledger.Dependency] = []
    for manifest in try trackedFiles(
      at: directory,
      pathspecs: ["Package.swift", ":(glob)**/Package.swift"]
    ) {
      let source = try text(at: "\(directory)/\(manifest)")
      for url in Institute.Architecture.Facts.Manifest.scan(source).dependencyURLs {
        let current = Institute.Architecture.Facts.Manifest.coordinate(url: url) ?? url
        dependencies.append(
          .init(
            manifest: manifest,
            current: current,
            future: mapping.coordinate(current)
          )
        )
      }
    }
    return dependencies.sorted {
      ($0.manifest, $0.current, $0.future) < ($1.manifest, $1.current, $1.future)
    }
  }

  internal static func trackedFiles(
    at directory: File.Directory,
    pathspecs: [Swift.String] = []
  ) throws(Error) -> [Swift.String] {
    var arguments = ["git", "-C", directory.description, "ls-files", "-z", "--"]
    arguments.append(contentsOf: pathspecs)
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
      throw .ledger("cannot enumerate tracked manifests at \(directory): \(error)")
    }
    guard case .exited(let code) = output.status, code == 0 else {
      throw .ledger(
        "git ls-files failed at \(directory): "
          + Swift.String(decoding: output.stderr ?? [], as: Swift.UTF8.self)
      )
    }
    return Swift.String(decoding: output.stdout ?? [], as: Swift.UTF8.self)
      .split(separator: "\0")
      .map(Swift.String.init)
      .sorted()
  }

  internal static func bytes(at path: Swift.String) throws(Error) -> [Byte] {
    let file: File
    do throws(File.Path.Error) {
      file = try File(.init(path))
    } catch {
      throw .ledger("invalid tracked manifest path \(path): \(error)")
    }
    do throws(Either<File.System.Read.Full.Error, Never>) {
      return try File.System.Read.Full.read(from: file.path) { span in
        var bytes: [Byte] = []
        bytes.reserveCapacity(span.count)
        for index in span.indices { bytes.append(span[index]) }
        return bytes
      }
    } catch {
      throw .ledger("cannot read tracked manifest \(path): \(error)")
    }
  }

  internal static func text(at path: Swift.String) throws(Error) -> Swift.String {
    Swift.String(decoding: try bytes(at: path), as: Swift.UTF8.self)
  }
}
