internal import Build_Coordinator
public import Command
internal import Institute_Conversion
internal import Institute_Dependency
internal import Institute_Development
internal import Institute_Doctor
internal import Institute_GitHub
internal import Institute_Instruments
internal import Institute_Inventory
internal import Institute_Lint
public import Institute_Model
internal import Institute_Pages

extension Institute.Application.CLI {
    /// The second positional component of a compound Institute operation.
    public enum Mode: Sendable, Equatable, Argument.Codable {
        case install
        case check
        case serve
        case build
        case test
        case run
        case resolve
        case update
        case regenerate
        case effective
        case clean
        case dumpPackage
        case lint
        case ledger
        case pages
        case seal
        case token
        case packet
        case validate
        case index
        case snapshot
        case assemble

        public init?(argument: Swift.String) {
            switch argument {
            case "install": self = .install
            case "check": self = .check
            case "serve": self = .serve
            case "build": self = .build
            case "test": self = .test
            case "run": self = .run
            case "resolve": self = .resolve
            case "update": self = .update
            case "regenerate": self = .regenerate
            case "effective": self = .effective
            case "clean": self = .clean
            case "dump-package": self = .dumpPackage
            case "lint": self = .lint
            case "ledger": self = .ledger
            case "pages": self = .pages
            case "seal": self = .seal
            case "token": self = .token
            case "packet": self = .packet
            case "validate": self = .validate
            case "index": self = .index
            case "snapshot": self = .snapshot
            case "assemble": self = .assemble
            default: return nil
            }
        }

        public var argumentDescription: Swift.String {
            switch self {
            case .install: "install"
            case .check: "check"
            case .serve: "serve"
            case .build: "build"
            case .test: "test"
            case .run: "run"
            case .resolve: "resolve"
            case .update: "update"
            case .regenerate: "regenerate"
            case .effective: "effective"
            case .clean: "clean"
            case .dumpPackage: "dump-package"
            case .lint: "lint"
            case .ledger: "ledger"
            case .pages: "pages"
            case .seal: "seal"
            case .token: "token"
            case .packet: "packet"
            case .validate: "validate"
            case .index: "index"
            case .snapshot: "snapshot"
            case .assemble: "assemble"
            }
        }
    }
}

extension Institute.Application.CLI.Mode {
    var buildAction: Build.Action? {
        switch self {
        case .install, .check, .serve, .regenerate, .effective, .lint, .ledger, .pages, .seal,
            .token, .packet, .validate, .index, .snapshot, .assemble:
            nil

        case .build: .build
        case .test: .test
        case .run: .run
        case .resolve: .resolve
        case .update: .update
        case .clean: .clean
        case .dumpPackage: .dumpPackage
        }
    }
}
