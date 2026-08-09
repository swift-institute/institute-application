import Foundation
import Testing
import WorkspaceArchitectureFacts
import WorkspaceArchitectureGraph
import WorkspaceArchitectureIndex
import WorkspaceArchitectureModel
import WorkspaceArchitectureValidation

@Suite
struct `Workspace Architecture Index Artifact Tests` {
    @Test
    func `emits complete validated canonical bytes`() throws {
        let artifact = try Artifact.fixture()

        #expect(artifact.rendered.contains("schema\tworkspace.architecture.index"))
        #expect(artifact.rendered.contains("version\t1"))
        #expect(artifact.rendered.contains("measurement\tcomplete\t2/2"))
        #expect(artifact.rendered.contains("index-digest\t\(artifact.index.digest)"))
        #expect(artifact.rendered.contains("validation\tvalid"))
        #expect(artifact.rendered.contains(
            "edge\truntime\tswift-foundations/swift-console\tswift-primitives/swift-byte-primitives"
        ))
        let owners = Swift.Set(artifact.index.entries.map(\.owner))
        #expect(artifact.edges.allSatisfy {
            owners.contains($0.source) && owners.contains($0.destination)
        })
        #expect(
            artifact.index.entries.reduce(0, { $0 + $1.edgeCount }) == artifact.edges.count
        )
        try Artifact.verify(artifact.rendered)
    }

    @Test
    func `regenerates byte-identically from permuted facts`() throws {
        let first = try Artifact.fixture()
        let second = try Artifact.fixture(reversed: true)

        #expect(first.digest == second.digest)
        #expect(first.rendered == second.rendered)
    }

    @Test
    func `canonicalizes duplicate edges into self-verifying bytes`() throws {
        let inputs = Artifact.inputs()
        let edge = try #require(inputs.edges.first)
        let facts = Workspace.Architecture.Facts(
            facts: inputs.facts,
            edges: [edge, edge]
        )
        let validation = Workspace.Architecture.Validator().validate(
            derived: facts,
            today: Artifact.today
        )

        let artifact = try Workspace.Architecture.Index.Artifact(
            facts: facts,
            validation: validation
        )

        #expect(artifact.edges == [edge])
        #expect(
            artifact.index.entries.first(where: { $0.owner == edge.source })?.edgeCount == 1
        )
        try Artifact.verify(artifact.rendered)
    }

    @Test
    func `rejects a fact whose concept identifier differs from its owner`() {
        let original = Artifact.fact(
            organization: "swift-primitives",
            name: "swift-byte-primitives",
            layer: .primitives,
            products: ["Byte Primitives"]
        )
        let mismatched = Workspace.Architecture.Fact(
            owner: original.owner,
            layer: original.layer,
            concept: .init(
                identifier: .init(rawValue: "swift-primitives/swift-other-primitives"),
                name: original.concept.name
            ),
            products: original.products,
            targets: original.targets
        )
        let facts = Workspace.Architecture.Facts(facts: [mismatched], edges: [])
        let validation = Workspace.Architecture.Validator().validate(
            derived: facts,
            today: Artifact.today
        )

        #expect(validation.passes)
        #expect(throws: Workspace.Architecture.Index.Artifact.Error.self) {
            _ = try Workspace.Architecture.Index.Artifact(
                facts: facts,
                validation: validation
            )
        }
    }

    @Test(arguments: [
        Workspace.Architecture.Owner(organization: "", name: "swift-byte-primitives"),
        Workspace.Architecture.Owner(organization: "swift-primitives", name: ""),
        Workspace.Architecture.Owner(organization: "swift/primitives", name: "swift-byte-primitives"),
        Workspace.Architecture.Owner(organization: "swift-primitives", name: "swift/byte-primitives"),
        Workspace.Architecture.Owner(organization: "swift\tprimitives", name: "swift-byte-primitives"),
        Workspace.Architecture.Owner(organization: "swift-primitives", name: "swift\tbyte-primitives"),
        Workspace.Architecture.Owner(organization: "swift\rprimitives", name: "swift-byte-primitives"),
        Workspace.Architecture.Owner(organization: "swift-primitives", name: "swift\rbyte-primitives"),
        Workspace.Architecture.Owner(organization: "swift\nprimitives", name: "swift-byte-primitives"),
        Workspace.Architecture.Owner(organization: "swift-primitives", name: "swift\nbyte-primitives"),
    ])
    func `rejects owners that cannot form canonical artifact coordinates`(
        _ owner: Workspace.Architecture.Owner
    ) {
        let fact = Workspace.Architecture.Fact(
            owner: owner,
            layer: .primitives,
            concept: .init(identifier: .init(owner: owner), name: "Byte Primitives"),
            products: ["Byte Primitives"],
            targets: ["Byte Primitives"]
        )
        let facts = Workspace.Architecture.Facts(facts: [fact], edges: [])
        let validation = Workspace.Architecture.Validator().validate(
            derived: facts,
            today: Artifact.today
        )

        #expect(validation.passes)
        #expect(!owner.isCanonical)
        #expect(Workspace.Architecture.Owner(coordinate: owner.description) == nil)
        #expect(throws: Workspace.Architecture.Index.Artifact.Error.self) {
            _ = try Workspace.Architecture.Index.Artifact(
                facts: facts,
                validation: validation
            )
        }
    }

    @Test
    func `round trips a canonical owner coordinate through an artifact`() throws {
        let owner = Workspace.Architecture.Owner(
            organization: "swift-primitives",
            name: "swift-byte_primitives.1"
        )
        let fact = Workspace.Architecture.Fact(
            owner: owner,
            layer: .primitives,
            concept: .init(identifier: .init(owner: owner), name: "Byte Primitives"),
            products: ["Byte Primitives"],
            targets: ["Byte Primitives"]
        )
        let facts = Workspace.Architecture.Facts(facts: [fact], edges: [])
        let validation = Workspace.Architecture.Validator().validate(
            derived: facts,
            today: Artifact.today
        )
        let artifact = try Workspace.Architecture.Index.Artifact(
            facts: facts,
            validation: validation
        )

        #expect(owner.isCanonical)
        #expect(Workspace.Architecture.Owner(coordinate: owner.description) == owner)
        try Workspace.Architecture.Index.Artifact.verify(
            artifact.rendered,
            facts: facts,
            validation: validation
        )
    }

    @Test
    func `refuses a tampered digest binding`() throws {
        let artifact = try Artifact.fixture()
        let tampered = artifact.rendered.replacingOccurrences(
            of: "validation\tvalid",
            with: "validation\tinvalid"
        )

        #expect(throws: Workspace.Architecture.Index.Artifact.Error.self) {
            try Artifact.verify(tampered)
        }
    }

    @Test
    func `refuses an incompatible schema`() throws {
        let artifact = try Artifact.fixture()
        let incompatible = artifact.rendered.replacingOccurrences(
            of: "version\t1",
            with: "version\t2"
        )

        #expect(throws: Workspace.Architecture.Index.Artifact.Error.self) {
            try Artifact.verify(incompatible)
        }
    }

    @Test
    func `refuses a passing report for different derived inputs`() throws {
        let facts = Artifact.inputs()
        let unrelated = Artifact.fact(
            organization: "swift-primitives",
            name: "swift-atom-primitives",
            layer: .primitives,
            products: ["Atom Primitives"]
        )
        let unrelatedFacts = Workspace.Architecture.Facts(facts: [unrelated], edges: [])
        let unrelatedValidation = Workspace.Architecture.Validator().validate(
            derived: unrelatedFacts,
            today: Artifact.today
        )

        #expect(unrelatedValidation.passes)
        #expect(throws: Workspace.Architecture.Index.Artifact.Error.self) {
            _ = try Workspace.Architecture.Index.Artifact(
                facts: facts,
                validation: unrelatedValidation
            )
        }
    }

    @Test
    func `refuses recomputed digests with tampered coverage`() throws {
        let artifact = try Artifact.fixture()
        let tampered = Artifact.recomputingDigest(
            artifact.rendered.replacingOccurrences(
                of: "measurement\tcomplete\t2/2",
                with: "measurement\tcomplete\t1/1"
            )
        )

        #expect(throws: Workspace.Architecture.Index.Artifact.Error.self) {
            try Artifact.verify(tampered)
        }
    }

    @Test
    func `refuses recomputed digests with an entry index mismatch`() throws {
        let artifact = try Artifact.fixture()
        let tampered = Artifact.recomputingDigest(
            artifact.rendered.replacingOccurrences(
                of: "products=1",
                with: "products=9"
            )
        )

        #expect(throws: Workspace.Architecture.Index.Artifact.Error.self) {
            try Artifact.verify(tampered)
        }
    }

    @Test
    func `refuses recomputed digests with a rewritten edge`() throws {
        let artifact = try Artifact.fixture()
        let tampered = Artifact.recomputingDigest(
            artifact.rendered.replacingOccurrences(
                of: "edge\truntime\tswift-foundations/swift-console\tswift-primitives/swift-byte-primitives",
                with: "edge\ttarget\tswift-foundations/swift-console\tswift-primitives/swift-byte-primitives"
            )
        )

        #expect(throws: Workspace.Architecture.Index.Artifact.Error.self) {
            try Artifact.verify(tampered)
        }
    }

    @Test
    func `refuses recomputed digests with a removed edge`() throws {
        let artifact = try Artifact.fixture()
        let tampered = Artifact.recomputingDigest(
            artifact.rendered.replacingOccurrences(
                of: "\nedge\truntime\tswift-foundations/swift-console\tswift-primitives/swift-byte-primitives",
                with: ""
            )
        )

        #expect(throws: Workspace.Architecture.Index.Artifact.Error.self) {
            try Artifact.verify(tampered)
        }
    }

    @Test
    func `refuses recomputed digests with an added edge`() throws {
        let artifact = try Artifact.fixture()
        let tampered = Artifact.recomputingDigest(
            artifact.rendered.replacingOccurrences(
                of: "edge\truntime\tswift-foundations/swift-console\tswift-primitives/swift-byte-primitives",
                with: "edge\truntime\tswift-foundations/swift-console\tswift-primitives/swift-byte-primitives\nedge\ttarget\tswift-foundations/swift-console\tswift-primitives/swift-byte-primitives"
            )
        )

        #expect(throws: Workspace.Architecture.Index.Artifact.Error.self) {
            try Artifact.verify(tampered)
        }
    }

    @Test
    func `refuses coverage that does not name exactly the indexed owners`() {
        let fact = Artifact.fact(
            organization: "swift-primitives",
            name: "swift-byte-primitives",
            layer: .primitives,
            products: ["Byte Primitives"]
        )
        let unrelated = Workspace.Architecture.Owner(
            organization: "swift-foundations",
            name: "swift-console"
        )
        let facts = Workspace.Architecture.Facts(
            facts: [fact],
            edges: [],
            coverage: .init(required: [fact.owner], measured: [fact.owner, unrelated])
        )
        let validation = Workspace.Architecture.Validator().validate(
            derived: facts,
            today: Artifact.today
        )

        #expect(validation.passes)
        #expect(throws: Workspace.Architecture.Index.Artifact.Error.self) {
            _ = try Workspace.Architecture.Index.Artifact(
                facts: facts,
                validation: validation
            )
        }
    }

    @Test
    func `refuses incomplete measurement instead of encoding a zero product fact`() {
        let measured = Artifact.fact(
            organization: "swift-primitives",
            name: "swift-byte-primitives",
            layer: .primitives,
            products: ["Byte Primitives"]
        )
        let missing = Workspace.Architecture.Owner(
            organization: "swift-foundations",
            name: "swift-console"
        )
        let facts = Workspace.Architecture.Facts(
            facts: [measured],
            edges: [],
            coverage: .init(required: [measured.owner, missing], measured: [measured.owner])
        )
        let validation = Workspace.Architecture.Validator().validate(
            derived: facts,
            today: Artifact.today
        )

        #expect(!validation.passes)
        #expect(facts.coverage.unmeasured == [missing])
        #expect(throws: Workspace.Architecture.Index.Artifact.Error.self) {
            _ = try Workspace.Architecture.Index.Artifact(
                facts: facts,
                validation: validation
            )
        }
    }

    @Test
    func `keeps a measured zero API package distinct from an unmeasured package`() throws {
        let empty = Artifact.fact(
            organization: "swift-primitives",
            name: "swift-internal-only",
            layer: .primitives,
            products: []
        )
        let facts = Workspace.Architecture.Facts(facts: [empty], edges: [])
        let validation = Workspace.Architecture.Validator().validate(
            derived: facts,
            today: Artifact.today
        )
        let artifact = try Workspace.Architecture.Index.Artifact(
            facts: facts,
            validation: validation
        )

        #expect(empty.classification == .internalOnly)
        #expect(artifact.rendered.contains("products=0"))
        #expect(artifact.coverage.complete)
    }

    @Test
    func `refuses forbidden fact edges without a caller-supplied graph`() {
        let lower = Artifact.fact(
            organization: "swift-primitives",
            name: "swift-byte-primitives",
            layer: .primitives,
            products: ["Byte Primitives"]
        )
        let higher = Artifact.fact(
            organization: "swift-foundations",
            name: "swift-console",
            layer: .foundations,
            products: ["Console"]
        )
        let facts = Workspace.Architecture.Facts(
            facts: [lower, higher],
            edges: [.init(source: lower.owner, destination: higher.owner, kind: .runtime)]
        )
        let validation = Workspace.Architecture.Validator().validate(
            derived: facts,
            today: Artifact.today
        )

        #expect(!validation.passes)
        #expect(throws: Workspace.Architecture.Index.Artifact.Error.self) {
            _ = try Workspace.Architecture.Index.Artifact(
                facts: facts,
                validation: validation
            )
        }
    }

    @Test
    func `keeps similarly named concepts distinct`() throws {
        let primitive = Artifact.fact(
            organization: "swift-primitives",
            name: "swift-json-primitives",
            layer: .primitives,
            products: ["JSON Primitives"]
        )
        let standard = Artifact.fact(
            organization: "swift-standards",
            name: "swift-json-standard",
            layer: .standards,
            products: ["JSON Standard"]
        )
        let facts = Workspace.Architecture.Facts(facts: [primitive, standard], edges: [])
        let validation = Workspace.Architecture.Validator().validate(
            derived: facts,
            today: Artifact.today
        )
        let artifact = try Workspace.Architecture.Index.Artifact(
            facts: facts,
            validation: validation
        )

        #expect(validation.passes)
        #expect(artifact.index.entries.map(\.concept) == [
            .init(owner: primitive.owner),
            .init(owner: standard.owner),
        ])
    }
}

private enum Artifact {
    static let today = try! Workspace.Architecture.Exemption.Expiry(rawValue: "2026-08-09")

    static func fixture(reversed: Swift.Bool = false) throws -> Workspace.Architecture.Index.Artifact {
        let facts = inputs(reversed: reversed)
        let validation = Workspace.Architecture.Validator().validate(
            derived: facts,
            today: today
        )
        return try .init(facts: facts, validation: validation)
    }

    static func verify(_ rendered: Swift.String) throws {
        let facts = inputs()
        let validation = Workspace.Architecture.Validator().validate(
            derived: facts,
            today: today
        )
        try Workspace.Architecture.Index.Artifact.verify(
            rendered,
            facts: facts,
            validation: validation
        )
    }

    static func inputs(
        reversed: Swift.Bool = false
    ) -> Workspace.Architecture.Facts {
        let primitive = fact(
            organization: "swift-primitives",
            name: "swift-byte-primitives",
            layer: .primitives,
            products: ["Byte Primitives"]
        )
        let foundation = fact(
            organization: "swift-foundations",
            name: "swift-console",
            layer: .foundations,
            products: ["Console"]
        )
        let values = reversed ? [foundation, primitive] : [primitive, foundation]
        let facts = Workspace.Architecture.Facts(
            facts: values,
            edges: [.init(source: foundation.owner, destination: primitive.owner, kind: .runtime)]
        )
        return facts
    }

    static func recomputingDigest(_ rendered: Swift.String) -> Swift.String {
        let payload = rendered
            .split(separator: "\n", omittingEmptySubsequences: false)
            .dropFirst()
            .joined(separator: "\n")
        return "digest\t\(Workspace.Architecture.Index.Digest(text: payload))\n\(payload)"
    }

    static func fact(
        organization: Swift.String,
        name: Swift.String,
        layer: Workspace.Architecture.Layer,
        products: [Swift.String]
    ) -> Workspace.Architecture.Fact {
        let owner = Workspace.Architecture.Owner(organization: organization, name: name)
        return .init(
            owner: owner,
            layer: layer,
            concept: .init(identifier: .init(owner: owner), name: name),
            products: products,
            targets: products
        )
    }
}
