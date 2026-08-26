import Institute_Architecture_Migration
import Institute_Model
import JSON
import Testing

@Suite
struct `Institute Architecture Migration Mapping Tests` {
  private let mapping = Institute.Architecture.Migration.Mapping()

  @Test
  func `maps the two realized layer organizations`() {
    #expect(mapping.organization("swift-primitives") == "swift-molecules")
    #expect(mapping.organization("swift-foundations") == "swift-compositions")
    #expect(mapping.organization("swift-standards") == "swift-standards")
  }

  @Test
  func `strips only the repository primitives suffix`() {
    #expect(
      mapping.repository(
        organization: "swift-primitives",
        name: "swift-byte-primitives"
      ) == "swift-byte"
    )
    #expect(
      mapping.repository(
        organization: "swift-primitives",
        name: "swift-standard-library-extensions"
      ) == "swift-standard-library-extensions"
    )
    #expect(
      mapping.repository(
        organization: "swift-primitives",
        name: "swift-foundation-extensions"
      ) == "swift-foundation-extensions"
    )
    #expect(
      mapping.repository(
        organization: "swift-primitives",
        name: "swift-primitives-linter-rules"
      ) == "swift-primitives-linter-rules"
    )
  }

  @Test
  func `removes plural product and module tokens but preserves singular primitive`() {
    #expect(
      mapping.product("Byte Primitives Standard Library Integration")
        == "Byte Standard Library Integration"
    )
    #expect(mapping.module("Byte_Primitives_Test_Support") == "Byte_Test_Support")
    #expect(mapping.product("Byte Primitive") == "Byte Primitive")
    #expect(mapping.module("Byte_Primitive") == "Byte_Primitive")
  }

  @Test
  func `round trips the durable ledger`() throws {
    let result = Institute.Architecture.Migration.Ledger.Result(status: .pending)
    let ledger = Institute.Architecture.Migration.Ledger(
      version: 1,
      inventoryCommit: Swift.String(repeating: "a", count: 40),
      organizations: [
        .init(
          current: "swift-primitives",
          future: "swift-molecules",
          kind: "layer",
          collisionCheck: result,
          publication: result
        )
      ],
      repositories: [
        .init(
          current: "swift-primitives/swift-byte-primitives",
          future: "swift-molecules/swift-byte",
          currentLayer: "primitives",
          futureLayer: "molecules",
          expectedCommit: Swift.String(repeating: "b", count: 40),
          expectedCommitSource: "fixture",
          observedHead: Swift.String(repeating: "b", count: 40),
          observedRemote: "https://github.com/swift-primitives/swift-byte-primitives.git",
          dirtyPaths: [],
          dependencies: [],
          state: .ready,
          preparation: result,
          validation: result,
          publication: result,
          disposition: result
        )
      ],
      decompositionQueue: ["swift-molecules/swift-byte"]
    )
    let encoded = ledger.jsonString(sortKeys: true)
    let decoded = try Institute.Architecture.Migration.Ledger(jsonString: encoded)
    #expect(decoded == ledger)
    #expect(decoded.jsonString(sortKeys: true) == encoded)
  }

  @Test
  func `transforms representative tracked text and paths without renaming the linter repository`() {
    let pending = Institute.Architecture.Migration.Ledger.Result(status: .pending)
    let repositories: [Institute.Architecture.Migration.Ledger.Repository] = [
      repository(
        current: "swift-primitives/swift-byte-primitives",
        future: "swift-molecules/swift-byte",
        pending: pending
      ),
      repository(
        current: "swift-primitives/swift-primitives-linter-rules",
        future: "swift-molecules/swift-primitives-linter-rules",
        pending: pending
      ),
    ]
    let ledger = Institute.Architecture.Migration.Ledger(
      version: 1,
      inventoryCommit: Swift.String(repeating: "a", count: 40),
      organizations: [],
      repositories: repositories,
      decompositionQueue: repositories.map(\.future)
    )
    let transformer = Institute.Architecture.Migration.Transformer(ledger: ledger)
    let transformed = transformer.text(
      """
      .package(url: "https://github.com/swift-primitives/swift-byte-primitives.git")
      .product(name: "Byte Primitives Standard Library Integration", package: "swift-byte-primitives")
      import Byte_Primitives_Standard_Library_Integration
      https://github.com/swift-primitives/swift-primitives-linter-rules
      """
    )
    #expect(transformed.contains("swift-molecules/swift-byte.git"))
    #expect(transformed.contains("package: \"swift-byte\""))
    #expect(transformed.contains("Byte Standard Library Integration"))
    #expect(transformed.contains("Byte_Standard_Library_Integration"))
    #expect(
      transformed.contains("swift-molecules/swift-primitives-linter-rules")
    )
    #expect(!transformed.contains("swift-molecules/swift-molecules-linter-rules"))
    #expect(
      transformer.path("Sources/Byte Primitives Standard Library Integration/exports.swift")
        == "Sources/Byte Standard Library Integration/exports.swift"
    )
    let plan = transformer.plan(files: [
      "Sources/Byte Primitives/exports.swift": "public import Byte_Primitives",
      "logo.png": nil,
    ])
    #expect(plan.count == 1)
    #expect(plan[0].currentPath == "Sources/Byte Primitives/exports.swift")
    #expect(plan[0].futurePath == "Sources/Byte/exports.swift")
    #expect(plan[0].futureText == "public import Byte")
  }

  private func repository(
    current: Swift.String,
    future: Swift.String,
    pending: Institute.Architecture.Migration.Ledger.Result
  ) -> Institute.Architecture.Migration.Ledger.Repository {
    .init(
      current: current,
      future: future,
      currentLayer: "primitives",
      futureLayer: "molecules",
      expectedCommit: nil,
      expectedCommitSource: "fixture",
      observedHead: nil,
      observedRemote: nil,
      dirtyPaths: [],
      dependencies: [],
      state: .ready,
      preparation: pending,
      validation: pending,
      publication: pending,
      disposition: pending
    )
  }
}
