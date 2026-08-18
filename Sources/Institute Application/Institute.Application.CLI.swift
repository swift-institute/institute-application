public import Build_Coordinator
public import Command
public import Console
public import Environment
public import File_System
public import GitHub_App
public import GitHub_HTTP
public import Git_Foundation
public import Institute_Conversion
public import Institute_Dependency
public import Institute_Development
public import Institute_Doctor
public import Institute_GitHub
public import Institute_Instruments
public import Institute_Inventory
public import Institute_Lint
public import Institute_Model
public import Institute_Pages
public import JSON
internal import Package_Manager
public import Process
internal import SPM_Standard

#if canImport(Darwin)
    private import Darwin
#elseif canImport(Glibc)
    private import Glibc
#elseif canImport(Musl)
    private import Musl
#endif

/// Writes a diagnostic through the cross-platform standard-error owner
/// (`Console.Output.error`, swift-console), which holds the one
/// sanctioned seam to the C `stderr` stream across Darwin, Glibc, and
/// Windows CRT. Failed writes are dropped there — a diagnostic never
/// takes the command down.
private func printToStandardError(_ text: Swift.String) {
    Console.Output.error(text)
}

extension Institute.Application {
    public struct CLI: Sendable, Command.`Protocol` {
        public var operation: Operation
        public var dry: Bool
        public var consumer: Swift.String
        public var dependency: Swift.String
        public var modes: [Mode]
        public var packagePath: Swift.String
        public var workspacePath: Swift.String
        public var fresh: Bool
        public var changed: Bool
        public var fix: Bool
        public var institute: Bool
        public var output: Institute.Dependency.Output?
        public var sanctionedExceptions: [Swift.String]
        public var arguments: [Swift.String]
        public var buildPath: Institute.Coherence.BuildPath?
        public var receiptPath: Swift.String
        public var jobs: Swift.Int?
        public var organization: Swift.String
        public var permissions: [Swift.String]
        public var applicationIdentity: Swift.String
        public var keyPath: Swift.String
        public var issue: Swift.String
        public var maxBytes: Swift.Int
        public var includedComments: [Swift.String]
        public var dispositions: [Swift.String]
        public var verifications: [Swift.String]
        public var claimedHead: Swift.String
        public var defaultBranch: Swift.String
        public var verificationVisibility: Swift.String
        public var verificationLayer: Swift.String
        public var inventoryDigest: Swift.String
        public var inventoryDigestCause: Swift.String
        public var inventoryScope: Swift.String
        public var inventoryOutput: Swift.String
        public var inventoryPrivateRoster: Swift.String
        public var workspaceRevision: Swift.String
        public var policyRevision: Swift.String
        public var requestedOperations: [Swift.String]
        public var requiredOperations: [Swift.String]
        public var platformSupport: [Swift.String]

        public init(
            operation: Operation = .sync,
            dry: Bool = false,
            consumer: Swift.String = "",
            dependency: Swift.String = "",
            modes: [Mode] = [],
            packagePath: Swift.String = "",
            workspacePath: Swift.String = "",
            fresh: Bool = false,
            changed: Bool = false,
            fix: Bool = false,
            institute: Bool = false,
            output: Institute.Dependency.Output? = nil,
            sanctionedExceptions: [Swift.String] = [],
            arguments: [Swift.String] = [],
            buildPath: Institute.Coherence.BuildPath? = nil,
            receiptPath: Swift.String = "",
            jobs: Swift.Int? = nil,
            organization: Swift.String = "",
            permissions: [Swift.String] = [],
            applicationIdentity: Swift.String = "",
            keyPath: Swift.String = "",
            issue: Swift.String = "",
            maxBytes: Swift.Int = 24_000,
            includedComments: [Swift.String] = [],
            dispositions: [Swift.String] = [],
            verifications: [Swift.String] = [],
            claimedHead: Swift.String = "",
            defaultBranch: Swift.String = "",
            verificationVisibility: Swift.String = "",
            verificationLayer: Swift.String = "",
            inventoryDigest: Swift.String = "",
            inventoryDigestCause: Swift.String = "",
            inventoryScope: Swift.String = "",
            inventoryOutput: Swift.String = "",
            inventoryPrivateRoster: Swift.String = "",
            workspaceRevision: Swift.String = "",
            policyRevision: Swift.String = "",
            requestedOperations: [Swift.String] = [],
            requiredOperations: [Swift.String] = [],
            platformSupport: [Swift.String] = []
        ) {
            self.operation = operation
            self.dry = dry
            self.consumer = consumer
            self.dependency = dependency
            self.modes = modes
            self.packagePath = packagePath
            self.workspacePath = workspacePath
            self.fresh = fresh
            self.changed = changed
            self.fix = fix
            self.institute = institute
            self.output = output
            self.sanctionedExceptions = sanctionedExceptions
            self.arguments = arguments
            self.buildPath = buildPath
            self.receiptPath = receiptPath
            self.jobs = jobs
            self.organization = organization
            self.permissions = permissions
            self.applicationIdentity = applicationIdentity
            self.keyPath = keyPath
            self.issue = issue
            self.maxBytes = maxBytes
            self.includedComments = includedComments
            self.dispositions = dispositions
            self.verifications = verifications
            self.claimedHead = claimedHead
            self.defaultBranch = defaultBranch
            self.verificationVisibility = verificationVisibility
            self.verificationLayer = verificationLayer
            self.inventoryDigest = inventoryDigest
            self.inventoryDigestCause = inventoryDigestCause
            self.inventoryScope = inventoryScope
            self.inventoryOutput = inventoryOutput
            self.inventoryPrivateRoster = inventoryPrivateRoster
            self.workspaceRevision = workspaceRevision
            self.policyRevision = policyRevision
            self.requestedOperations = requestedOperations
            self.requiredOperations = requiredOperations
            self.platformSupport = platformSupport
        }
    }
}

extension Institute.Application.CLI {
    public static var configuration: Command.Configuration {
        .init(
            name: "institute",
            abstract: "Synchronize, diagnose, and operate the public Swift Institute workspace."
        )
    }

    public static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(
                \.operation,
                name: "operation",
                placeholder:
                    "install|sync|build|doctor|inventory|dependencies|compose|restore|verify|context"
                    + "|navigation|package|lint|coherence|conversion|github|verification|certification",
                help: .init(abstract: "Operation to perform.")
            )
            Command.Positional<Self, Mode>.Many(
                \.modes,
                name: "mode",
                placeholder:
                    "install|check|packet|serve|build|test|run|resolve|update|regenerate|effective|clean|dump-package"
                    + "|lint|ledger|pages|seal|token|validate|index|snapshot",
                arity: .atMost(1),
                help: .init(
                    abstract:
                        "Required after context, navigation, package, conversion, or github; "
                        + "optional after inventory or lint. Use lint ledger for the complete "
                        + "residual compliance report."
                )
            )
            Command.Flag(
                \.dry,
                name: .long(.literal("dry-run")),
                help: .init(
                    abstract:
                        "Plan synchronization or inventory regeneration without changing files "
                        + "or Git metadata."
                )
            )
            Command.Flag(
                \.fresh,
                name: .long(.literal("fresh")),
                help: .init(
                    abstract:
                        "Use isolated build state — a scratch directory for a package build or "
                        + "test, a derived-data directory for the workspace build."
                )
            )
            Command.Flag(
                \.changed,
                name: .long(.literal("changed")),
                help: .init(
                    abstract:
                        "Sweep only packages with local work — an unclean worktree, or commits not "
                        + "yet in the tracked upstream (lint sweep only)."
                )
            )
            Command.Flag(
                \.fix,
                name: .long(.literal("fix")),
                help: .init(
                    abstract:
                        "Apply the canonical fix of every rewriter-backed rule instead of "
                        + "reporting findings (lint sweep or package lint). Add --dry-run to "
                        + "print the diffs without writing."
                )
            )
            Command.Flag(
                \.institute,
                name: .long(.literal("institute")),
                help: .init(
                    abstract:
                        "Run the institute-internal doctor checks too, which discover the live "
                        + "GitHub organizations (needs an authenticated gh; ~460 requests)."
                )
            )
            Command.Option(
                \.output,
                name: .long(.literal("format")),
                placeholder: "human|json",
                help: .init(
                    abstract:
                        "Render a concise human summary or deterministic JSON "
                        + "(dependencies, context packet, or lint ledger; defaults to human)."
                )
            )
            Command.Option(
                \.issue,
                name: .long(.literal("issue")),
                placeholder: "owner/repository#N",
                help: .init(
                    abstract: "Issue whose current context is rendered (context packet only)."
                )
            )
            Command.Option(
                \.maxBytes,
                name: .long(.literal("max-bytes")),
                placeholder: "n",
                help: .init(
                    abstract:
                        "Maximum rendered packet bytes (context packet only; defaults to 24000)."
                )
            )
            Command.Option<Self, Swift.String>.Many(
                \.includedComments,
                name: .long(.literal("include-comment")),
                placeholder: "URL",
                help: .init(
                    abstract:
                        "Explicit Issue comment URL to include (context packet only; repeatable)."
                )
            )
            Command.Option<Self, Swift.String>.Many(
                \.dispositions,
                name: .long(.literal("disposition")),
                placeholder: "rule=state@owner/repository#N",
                help: .init(
                    abstract:
                        "Supply one terminal advisory disposition and exact owner Issue "
                        + "(lint ledger only; repeatable)."
                )
            )
            Command.Option<Self, Swift.String>.Many(
                \.verifications,
                name: .long(.literal("verification")),
                placeholder: "owner/repository@sha=actions-run-url",
                help: .init(
                    abstract:
                        "Supply one exact-head successful GitHub Actions coordinate "
                        + "(lint ledger only; repeatable)."
                )
            )
            Command.Option<Self, Swift.String>.Many(
                \.sanctionedExceptions,
                name: .long(.literal("sanctioned-exception")),
                placeholder: "owner/repository",
                help: .init(
                    abstract:
                        "Classify this canonical repository identity as a policy-supplied "
                        + "sanctioned exception (dependencies only; repeatable)."
                )
            )
            Command.Option(
                \.consumer,
                name: .long(.literal("consumer")),
                placeholder: "repository",
                help: .init(
                    abstract:
                        "Institute repository whose manifest is composed (compose/restore/verify)."
                )
            )
            Command.Option(
                \.dependency,
                name: .long(.literal("dependency")),
                placeholder: "repository",
                help: .init(
                    abstract:
                        "Institute repository redirected to a local source (compose/restore/verify)."
                )
            )
            Command.Option(
                \.packagePath,
                name: .long(.literal("package-path")),
                placeholder: "path",
                help: .init(
                    abstract: "Package root for a package operation (defaults to PWD)."
                )
            )
            Command.Option(
                \.workspacePath,
                name: .long(.literal("workspace-path")),
                placeholder: "path",
                help: .init(
                    abstract: "Institute checkout a navigation or lint invocation resolves against."
                )
            )
            Command.Option<Self, Swift.String>.Many(
                \.arguments,
                name: .long(.literal("argument")),
                placeholder: "swiftpm-argument",
                help: .init(
                    abstract:
                        "Argument forwarded to the underlying tool (repeatable) — SwiftPM for a "
                        + "package operation, xcodebuild for the workspace build."
                )
            )
            Command.Option(
                \.jobs,
                name: .long(.literal("jobs")),
                placeholder: "n",
                help: .init(
                    abstract:
                        "Cap compile jobs the coordinator gives SwiftPM (package build or test "
                        + "only); defaults to the machine's processor count."
                )
            )
            Command.Option(
                \.buildPath,
                name: .long(.literal("build-path")),
                placeholder: "xcodebuild-merged|swiftpm-composed-root",
                help: .init(
                    abstract:
                        "Which build path measures coherence (defaults to xcodebuild-merged, "
                        + "issue #80); swiftpm-composed-root is the Ubuntu-capable Phase 2 path "
                        + "(issue #81)."
                )
            )
            Command.Option(
                \.receiptPath,
                name: .long(.literal("receipt")),
                placeholder: "path",
                help: .init(
                    abstract:
                        "Conversion receipt file `conversion check` re-reads (issue #83); "
                        + "`verification seal`'s output path or `verification check`'s input path "
                        + "(#253)."
                )
            )
            Command.Option(
                \.claimedHead,
                name: .long(.literal("claimed-head")),
                placeholder: "40-hex-sha",
                help: .init(
                    abstract:
                        "The commit the caller believes the subject checkout stands on "
                        + "(verification seal only); refused if it does not match the checked-out "
                        + "HEAD."
                )
            )
            Command.Option(
                \.defaultBranch,
                name: .long(.literal("default-branch")),
                placeholder: "name",
                help: .init(
                    abstract:
                        "The subject repository's default branch, as the caller resolved it "
                        + "(verification seal only)."
                )
            )
            Command.Option(
                \.verificationVisibility,
                name: .long(.literal("visibility")),
                placeholder: "public|private|unmeasured",
                help: .init(
                    abstract: "The subject repository's visibility, as the caller resolved it "
                        + "(verification seal only); never interrogated live."
                )
            )
            Command.Option(
                \.verificationLayer,
                name: .long(.literal("layer")),
                placeholder: "primitives|standards|foundations|components|applications",
                help: .init(
                    abstract:
                        "The subject's effective-inventory layer, as the caller resolved it "
                        + "(verification seal only)."
                )
            )
            Command.Option(
                \.inventoryDigest,
                name: .long(.literal("inventory-digest")),
                placeholder: "hex",
                help: .init(
                    abstract:
                        "The effective Institute inventory digest measuring this run "
                        + "(verification seal only); see `Institute.Inventory.Effective` (#132)."
                )
            )
            Command.Option(
                \.inventoryDigestCause,
                name: .long(.literal("inventory-digest-cause")),
                placeholder: "reason",
                help: .init(
                    abstract:
                        "Why no effective-inventory digest was established (verification seal "
                        + "only). Required with --inventory-digest unmeasured, and refused "
                        + "with a real digest; see `Institute.Verification.Inventory.Digest`."
                )
            )
            Command.Option(
                \.inventoryScope,
                name: .long(.literal("inventory-scope")),
                placeholder: "public|effective",
                help: .init(
                    abstract:
                        "The population breadth the effective-inventory report covers "
                        + "(inventory effective only): the committed public roster alone, or "
                        + "combined with one authorized private discovery pass."
                )
            )
            Command.Option(
                \.inventoryOutput,
                name: .long(.literal("inventory-output")),
                placeholder: "path",
                help: .init(
                    abstract:
                        "Where the effective-inventory report is written atomically "
                        + "(inventory effective only)."
                )
            )
            Command.Option(
                \.inventoryPrivateRoster,
                name: .long(.literal("inventory-private-roster")),
                placeholder: "path",
                help: .init(
                    abstract:
                        "A private population this process is not credentialed to discover, "
                        + "supplied as a roster file instead of read live (inventory effective, "
                        + "--inventory-scope effective only); see "
                        + "`Institute.Inventory.Effective.Roster`."
                )
            )
            Command.Option(
                \.workspaceRevision,
                name: .long(.literal("workspace-revision")),
                placeholder: "40-hex-sha",
                help: .init(
                    abstract:
                        "The Institute source/executable revision performing this run "
                        + "(verification seal only)."
                )
            )
            Command.Option(
                \.policyRevision,
                name: .long(.literal("policy-revision")),
                placeholder: "revision",
                help: .init(
                    abstract:
                        "The control plane's universal policy/fixture revision this run measures "
                        + "against (verification seal only)."
                )
            )
            Command.Option<Self, Swift.String>.Many(
                \.requestedOperations,
                name: .long(.literal("step")),
                placeholder: "build|test|nested-tests|lint",
                help: .init(
                    abstract:
                        "One operation to perform (verification seal only; repeatable; defaults "
                        + "to build, test, and lint)."
                )
            )
            Command.Option<Self, Swift.String>.Many(
                \.requiredOperations,
                name: .long(.literal("required-step")),
                placeholder: "build|test|nested-tests|lint",
                help: .init(
                    abstract:
                        "One operation whose absence or non-execution refuses the seal "
                        + "(verification seal only; repeatable; defaults to every --step)."
                )
            )
            Command.Option<Self, Swift.String>.Many(
                \.platformSupport,
                name: .long(.literal("platform-support")),
                placeholder: "name",
                help: .init(
                    abstract:
                        "One declared supported-platform name, carried verbatim "
                        + "(verification seal only; repeatable)."
                )
            )
            Command.Option(
                \.organization,
                name: .long(.literal("org")),
                placeholder: "organization",
                help: .init(
                    abstract:
                        "GitHub organization whose installation token is minted (github token)."
                )
            )
            Command.Option<Self, Swift.String>.Many(
                \.permissions,
                name: .long(.literal("permission")),
                placeholder: "name=level",
                help: .init(
                    abstract:
                        "Narrow the minted token to this permission (github token; repeatable). "
                        + "Without one the token carries the installation's whole grant."
                )
            )
            Command.Option(
                \.applicationIdentity,
                name: .long(.literal("app-id")),
                placeholder: "identity",
                help: .init(
                    abstract:
                        "GitHub App identity to mint as; defaults to GITHUB_APP_ID, then the "
                        + "identity file in the configuration directory."
                )
            )
            Command.Option(
                \.keyPath,
                name: .long(.literal("key")),
                placeholder: "path",
                help: .init(
                    abstract:
                        "Signing key to use; defaults to GITHUB_APP_PRIVATE_KEY_PATH, then the "
                        + "sole .pem in the configuration directory."
                )
            )
        }
    }

    public mutating func validate() throws(Command.Error) {
        // Rejected rather than ignored, for the same reason `--institute` is:
        // a credential flag silently dropped mints a *wider* token than the
        // caller asked for, and nothing downstream can tell the difference.
        guard
            operation == .github
                || (organization.isEmpty && permissions.isEmpty && applicationIdentity.isEmpty
                    && keyPath.isEmpty)
        else {
            throw .validationFailed(
                reason: "--org, --permission, --app-id, and --key are valid only with github token."
            )
        }
        guard
            (operation == .context && modes.first == .packet)
                || (issue.isEmpty && maxBytes == 24_000 && includedComments.isEmpty)
        else {
            throw .validationFailed(
                reason:
                    "--issue, --max-bytes, and --include-comment are valid only with context packet."
            )
        }
        guard operation == .lint || !changed else {
            throw .validationFailed(reason: "--changed is valid only with the lint sweep.")
        }
        // Rejected rather than ignored, for the reason every flag here is:
        // a `--fix` that was silently dropped would leave the caller reading
        // a findings report and believing it was a record of what had just
        // been repaired.
        guard operation == .lint || (operation == .package && modes.first == .lint) || !fix else {
            throw .validationFailed(
                reason: "--fix is valid only with the lint sweep or `package lint`."
            )
        }
        // Rejected rather than ignored: a flag that asks for a measurement
        // and is silently dropped produces a report that looks like the one
        // that measured, which is the defect `--institute` exists to fix.
        guard operation == .doctor || !institute else {
            throw .validationFailed(reason: "--institute is valid only with doctor.")
        }
        guard operation == .coherence || buildPath == nil else {
            throw .validationFailed(reason: "--build-path is valid only with coherence.")
        }
        // Only build and test ever reach `Build.Action.acceptsJobs`; a cap
        // silently accepted anywhere else would look like it did something.
        guard
            jobs == nil
                || (operation == .package
                    && (modes.first?.buildAction == .build || modes.first?.buildAction == .test))
        else {
            throw .validationFailed(reason: "--jobs is valid only with package build or test.")
        }
        let ledger = operation == .lint && modes.first == .ledger
        guard
            operation == .dependencies
                || (operation == .context && modes.first == .packet)
                || ledger
                || (output == nil && sanctionedExceptions.isEmpty)
        else {
            throw .validationFailed(
                reason:
                    "--format is valid only with dependencies, context packet, or lint ledger; "
                    + "--sanctioned-exception is valid only with dependencies."
            )
        }
        guard operation == .dependencies || sanctionedExceptions.isEmpty else {
            throw .validationFailed(
                reason: "--sanctioned-exception is valid only with dependencies."
            )
        }
        guard ledger || (dispositions.isEmpty && verifications.isEmpty) else {
            throw .validationFailed(
                reason: "--disposition and --verification are valid only with lint ledger."
            )
        }
        if operation == .dependencies {
            guard modes.isEmpty else {
                throw .validationFailed(reason: "dependencies takes no mode.")
            }
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason: "--consumer and --dependency are not valid with dependencies."
                )
            }
            guard !dry, !fresh, !changed, !institute else {
                throw .validationFailed(
                    reason:
                        "--dry-run, --fresh, --changed, and --institute are not valid with dependencies."
                )
            }
            guard packagePath.isEmpty, workspacePath.isEmpty, arguments.isEmpty else {
                throw .validationFailed(
                    reason:
                        "--package-path, --workspace-path, and --argument are not valid with dependencies."
                )
            }
            var exceptions = Set<Institute.Repository.Key>()
            for value in sanctionedExceptions {
                guard let key = Institute.Repository.Key(identity: value) else {
                    throw .validationFailed(
                        reason: "invalid sanctioned exception \(value); expected owner/repository."
                    )
                }
                guard exceptions.insert(key).inserted else {
                    throw .validationFailed(
                        reason: "duplicate sanctioned exception \(value)."
                    )
                }
            }
        } else if operation == .install {
            guard modes.isEmpty else {
                throw .validationFailed(reason: "install takes no mode.")
            }
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason: "--consumer and --dependency are not valid with install."
                )
            }
            guard !dry else {
                throw .validationFailed(
                    reason: "--dry-run is valid only with sync or inventory regenerate."
                )
            }
            guard !fresh else {
                throw .validationFailed(reason: "--fresh is valid only with package build or test.")
            }
            guard packagePath.isEmpty else {
                throw .validationFailed(reason: "--package-path is valid only with package.")
            }
            guard workspacePath.isEmpty else {
                throw .validationFailed(
                    reason: "--workspace-path is valid only with navigation or lint."
                )
            }
            guard arguments.isEmpty else {
                throw .validationFailed(reason: "--argument is valid only with package.")
            }
        } else if operation == .context {
            guard
                modes.count == 1,
                modes.first == .install || modes.first == .check || modes.first == .packet
            else {
                throw .validationFailed(reason: "context requires install, check, or packet.")
            }
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason: "--consumer and --dependency are not valid with context."
                )
            }
            guard !dry else {
                throw .validationFailed(
                    reason: "--dry-run is valid only with sync or inventory regenerate."
                )
            }
            guard !fresh else {
                throw .validationFailed(reason: "--fresh is valid only with package build or test.")
            }
            guard packagePath.isEmpty else {
                throw .validationFailed(reason: "--package-path is valid only with package.")
            }
            guard workspacePath.isEmpty else {
                throw .validationFailed(reason: "--workspace-path is valid only with navigation.")
            }
            guard arguments.isEmpty else {
                throw .validationFailed(reason: "--argument is valid only with package.")
            }
            guard
                modes.first == .packet
                    || (issue.isEmpty && includedComments.isEmpty && maxBytes == 24_000)
            else {
                throw .validationFailed(
                    reason:
                        "--issue, --max-bytes, and --include-comment are valid only with context packet."
                )
            }
            if modes.first == .packet {
                guard Institute.Context.Packet.Key(argument: issue) != nil else {
                    throw .validationFailed(
                        reason: "context packet requires --issue owner/repository#N."
                    )
                }
                guard maxBytes >= 512 else {
                    throw .validationFailed(
                        reason: "context packet --max-bytes must be at least 512."
                    )
                }
            }
        } else if operation == .navigation {
            guard
                modes.count == 1,
                modes.first == .install || modes.first == .check || modes.first == .serve
            else {
                throw .validationFailed(reason: "navigation requires install, check, or serve.")
            }
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason: "--consumer and --dependency are not valid with navigation."
                )
            }
            guard !dry else {
                throw .validationFailed(
                    reason: "--dry-run is valid only with sync or inventory regenerate."
                )
            }
            guard !fresh else {
                throw .validationFailed(reason: "--fresh is valid only with package build or test.")
            }
            guard packagePath.isEmpty else {
                throw .validationFailed(reason: "--package-path is valid only with package.")
            }
            guard arguments.isEmpty else {
                throw .validationFailed(reason: "--argument is valid only with package.")
            }
        } else if operation == .lint {
            guard
                modes.isEmpty || modes.first == .install || modes.first == .check
                    || modes.first == .ledger
            else {
                throw .validationFailed(
                    reason:
                        "lint takes install, check, ledger, or no mode (the ecosystem sweep)."
                )
            }
            guard modes.isEmpty || !changed else {
                throw .validationFailed(reason: "--changed is valid only with the lint sweep.")
            }
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason: "--consumer and --dependency are not valid with lint."
                )
            }
            // `--fix --dry-run` is the preview of a fix run — the one place
            // `--dry-run` means something here, and the only place it does.
            guard !dry || fix else {
                throw .validationFailed(
                    reason: "--dry-run is valid only with sync or inventory regenerate."
                )
            }
            guard !fresh else {
                throw .validationFailed(reason: "--fresh is valid only with package build or test.")
            }
            guard modes.first != .ledger || (!fix && !dry) else {
                throw .validationFailed(
                    reason: "lint ledger is read-only; --fix and --dry-run are not valid."
                )
            }
            if modes.first == .ledger {
                var dispositionRules = Swift.Set<Swift.String>()
                for value in dispositions {
                    guard let disposition = Institute.Lint.Ledger.Disposition(argument: value)
                    else {
                        throw .validationFailed(
                            reason:
                                "invalid disposition \(value); expected "
                                + "rule=state@owner/repository#N."
                        )
                    }
                    guard dispositionRules.insert(disposition.rule).inserted else {
                        throw .validationFailed(
                            reason: "duplicate disposition for rule \(disposition.rule)."
                        )
                    }
                }
                var verificationRepositories = Swift.Set<Institute.Repository.Key>()
                for value in verifications {
                    guard let verification = Institute.Lint.Ledger.Verification(argument: value)
                    else {
                        throw .validationFailed(
                            reason:
                                "invalid verification \(value); expected "
                                + "owner/repository@<40-hex-sha>=<actions-run-url>."
                        )
                    }
                    guard verificationRepositories.insert(verification.repository).inserted else {
                        throw .validationFailed(
                            reason:
                                "duplicate verification for "
                                + "\(verification.repository.identity)."
                        )
                    }
                }
            }
            guard packagePath.isEmpty else {
                throw .validationFailed(
                    reason: "--package-path is valid only with package; lint sweeps the inventory."
                )
            }
            guard arguments.isEmpty else {
                throw .validationFailed(reason: "--argument is valid only with package.")
            }
        } else if operation == .package {
            guard modes.count == 1, let mode = modes.first else {
                throw .validationFailed(
                    reason:
                        "package requires build, test, run, resolve, update, clean, dump-package, lint, or check."
                )
            }
            let action = mode.buildAction
            guard action != nil || mode == .lint || mode == .check else {
                throw .validationFailed(
                    reason:
                        "package requires build, test, run, resolve, update, clean, dump-package, lint, or check."
                )
            }
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason: "--consumer and --dependency are not valid with package."
                )
            }
            // `--fix --dry-run` previews a `package lint --fix`; nothing else
            // in this branch has a plan to show.
            guard !dry || (fix && mode == .lint) else {
                throw .validationFailed(
                    reason: "--dry-run is valid only with sync or inventory regenerate."
                )
            }
            guard !fresh || action == .build || action == .test || mode == .check else {
                throw .validationFailed(
                    reason: "--fresh is valid only with package build, test, or check."
                )
            }
            guard workspacePath.isEmpty else {
                throw .validationFailed(reason: "--workspace-path is valid only with navigation.")
            }
        } else if operation.composesADependency {
            guard modes.isEmpty else {
                throw .validationFailed(reason: "install and check are valid only after context.")
            }
            guard !consumer.isEmpty else {
                throw .validationFailed(
                    reason: "\(operation.argumentDescription) requires --consumer."
                )
            }
            guard !dependency.isEmpty else {
                throw .validationFailed(
                    reason: "\(operation.argumentDescription) requires --dependency."
                )
            }
            guard !dry else {
                throw .validationFailed(
                    reason: "--dry-run is valid only with sync or inventory regenerate."
                )
            }
            guard !fresh, packagePath.isEmpty, workspacePath.isEmpty else {
                throw .validationFailed(
                    reason: "--fresh, --package-path, and --workspace-path are not valid here."
                )
            }
            guard arguments.isEmpty else {
                throw .validationFailed(reason: "--argument is valid only with package.")
            }
        } else if operation == .inventory {
            guard
                modes.isEmpty
                    || (modes.count == 1
                        && (modes.first == .regenerate || modes.first == .pages
                            || modes.first == .effective))
            else {
                throw .validationFailed(
                    reason:
                        "inventory takes regenerate, pages, effective, or no mode (the read-only "
                        + "register)."
                )
            }
            guard
                modes.first == .effective
                    || (inventoryScope.isEmpty && inventoryOutput.isEmpty
                        && inventoryPrivateRoster.isEmpty)
            else {
                throw .validationFailed(
                    reason:
                        "--inventory-scope, --inventory-output, and --inventory-private-roster "
                        + "are valid only with inventory effective."
                )
            }
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason: "--consumer and --dependency are not valid with inventory."
                )
            }
            guard !dry || modes.first == .regenerate else {
                throw .validationFailed(
                    reason:
                        "--dry-run is valid only with inventory regenerate; inventory is already "
                        + "read-only."
                )
            }
            guard !fresh, packagePath.isEmpty, workspacePath.isEmpty else {
                throw .validationFailed(
                    reason: "--fresh, --package-path, and --workspace-path are not valid here."
                )
            }
            guard arguments.isEmpty else {
                throw .validationFailed(reason: "--argument is valid only with package.")
            }
        } else if operation == .conversion {
            guard
                modes.count == 1,
                modes.first == .seal || modes.first == .check
            else {
                throw .validationFailed(reason: "conversion requires seal or check.")
            }
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason: "--consumer and --dependency are not valid with conversion."
                )
            }
            guard !dry else {
                throw .validationFailed(
                    reason: "--dry-run is valid only with sync or inventory regenerate."
                )
            }
            guard !fresh else {
                throw .validationFailed(reason: "--fresh is valid only with package build or test.")
            }
            guard packagePath.isEmpty, workspacePath.isEmpty else {
                throw .validationFailed(
                    reason: "--package-path and --workspace-path are not valid with conversion."
                )
            }
            guard arguments.isEmpty else {
                throw .validationFailed(reason: "--argument is valid only with package.")
            }
            guard modes.first == .check || receiptPath.isEmpty else {
                throw .validationFailed(reason: "--receipt is valid only with conversion check.")
            }
            guard modes.first != .check || !receiptPath.isEmpty else {
                throw .validationFailed(reason: "conversion check requires --receipt.")
            }
        } else if operation == .github {
            guard modes.count == 1, modes.first == .token else {
                throw .validationFailed(reason: "github requires token.")
            }
            guard !organization.isEmpty else {
                throw .validationFailed(reason: "github token requires --org.")
            }
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason: "--consumer and --dependency are not valid with github."
                )
            }
            guard !dry, !fresh else {
                throw .validationFailed(
                    reason: "--dry-run and --fresh are not valid with github."
                )
            }
            guard packagePath.isEmpty, workspacePath.isEmpty, arguments.isEmpty else {
                throw .validationFailed(
                    reason:
                        "--package-path, --workspace-path, and --argument are not valid with github."
                )
            }
        } else if operation == .build {
            guard modes.isEmpty else {
                throw .validationFailed(
                    reason: "build takes no mode; it builds the whole selection."
                )
            }
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason: "--consumer and --dependency are not valid with build."
                )
            }
            guard !dry else {
                throw .validationFailed(
                    reason: "--dry-run is valid only with sync or inventory regenerate."
                )
            }
            guard packagePath.isEmpty else {
                throw .validationFailed(
                    reason: "--package-path is valid only with package; build builds the selection."
                )
            }
            guard workspacePath.isEmpty else {
                throw .validationFailed(
                    reason: "--workspace-path is valid only with navigation or lint."
                )
            }
        } else if operation == .coherence {
            guard modes.isEmpty else {
                throw .validationFailed(
                    reason: "coherence takes no mode; it measures the whole selection."
                )
            }
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason: "--consumer and --dependency are not valid with coherence."
                )
            }
            guard !dry else {
                throw .validationFailed(
                    reason: "--dry-run is valid only with sync or inventory regenerate."
                )
            }
            guard !fresh else {
                throw .validationFailed(reason: "--fresh is valid only with package build or test.")
            }
            guard packagePath.isEmpty else {
                throw .validationFailed(
                    reason:
                        "--package-path is valid only with package; coherence measures the selection."
                )
            }
            guard workspacePath.isEmpty else {
                throw .validationFailed(
                    reason: "--workspace-path is valid only with navigation or lint."
                )
            }
            guard arguments.isEmpty else {
                throw .validationFailed(reason: "--argument is valid only with package.")
            }
        } else if operation == .certification {
            guard modes.count == 1, modes.first == .snapshot || modes.first == .run else {
                throw .validationFailed(reason: "certification requires snapshot or run.")
            }
            guard modes.first == .snapshot || !receiptPath.isEmpty else {
                throw .validationFailed(
                    reason: "certification run requires --receipt (the frozen snapshot path)."
                )
            }
            guard !fresh || modes.first == .run else {
                throw .validationFailed(reason: "--fresh is valid only with certification run.")
            }
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason: "--consumer and --dependency are not valid with certification."
                )
            }
            guard !dry else {
                throw .validationFailed(
                    reason: "--dry-run is valid only with sync or inventory regenerate."
                )
            }
            guard packagePath.isEmpty else {
                throw .validationFailed(
                    reason: "--package-path is valid only with package; "
                        + "certification derives the whole inventory."
                )
            }
            guard workspacePath.isEmpty else {
                throw .validationFailed(
                    reason: "--workspace-path is valid only with navigation or lint."
                )
            }
        } else if operation == .verification {
            guard modes.count == 1, let mode = modes.first, mode == .seal || mode == .check else {
                throw .validationFailed(reason: "verification requires seal or check.")
            }
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason: "--consumer and --dependency are not valid with verification."
                )
            }
            guard !dry else {
                throw .validationFailed(
                    reason: "--dry-run is valid only with sync or inventory regenerate."
                )
            }
            guard !receiptPath.isEmpty else {
                throw .validationFailed(
                    reason:
                        "verification requires --receipt (seal's output path, check's input path)."
                )
            }
            if mode == .seal {
                guard !claimedHead.isEmpty else {
                    throw .validationFailed(reason: "verification seal requires --claimed-head.")
                }
                guard !defaultBranch.isEmpty else {
                    throw .validationFailed(reason: "verification seal requires --default-branch.")
                }
                guard Institute.Verification.Visibility(rawValue: verificationVisibility) != nil
                else {
                    throw .validationFailed(
                        reason:
                            "verification seal requires --visibility public, private, or unmeasured."
                    )
                }
                guard Institute.Layer(rawValue: verificationLayer) != nil else {
                    throw .validationFailed(
                        reason:
                            "verification seal requires --layer primitives, standards, foundations, "
                            + "components, or applications."
                    )
                }
                guard !inventoryDigest.isEmpty else {
                    throw .validationFailed(
                        reason: "verification seal requires --inventory-digest."
                    )
                }
                // The digest and its cause are validated together, here, so
                // an unmeasured digest without a cause is refused before a
                // run starts rather than sealed and discovered downstream.
                do throws(Institute.Verification.Inventory.Digest.Error) {
                    _ = try Institute.Verification.Inventory.Digest(
                        token: inventoryDigest,
                        cause: inventoryDigestCause.isEmpty ? nil : inventoryDigestCause
                    )
                } catch {
                    throw .validationFailed(reason: "verification seal: \(error).")
                }
                guard !workspaceRevision.isEmpty else {
                    throw .validationFailed(
                        reason: "verification seal requires --workspace-revision."
                    )
                }
                guard !policyRevision.isEmpty else {
                    throw .validationFailed(reason: "verification seal requires --policy-revision.")
                }
                for value in requestedOperations + requiredOperations {
                    guard Institute.Verification.Operation.Kind(rawValue: value) != nil else {
                        throw .validationFailed(
                            reason:
                                "\(value) is not build, test, nested-tests, or lint "
                                + "(--step/--required-step)."
                        )
                    }
                }
            } else {
                guard
                    packagePath.isEmpty, claimedHead.isEmpty, defaultBranch.isEmpty,
                    verificationVisibility.isEmpty,
                    verificationLayer.isEmpty, inventoryDigest.isEmpty, workspaceRevision.isEmpty,
                    policyRevision.isEmpty, requestedOperations.isEmpty, requiredOperations.isEmpty,
                    platformSupport.isEmpty, arguments.isEmpty, !fresh, jobs == nil
                else {
                    throw .validationFailed(reason: "verification check takes only --receipt.")
                }
            }
        } else if operation == .architecture {
            guard modes == [.validate] || modes == [.index] else {
                throw .validationFailed(reason: "architecture operation must be validate or index.")
            }
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason:
                        "--consumer and --dependency are valid only with compose, restore, or verify."
                )
            }
            guard !dry, !fresh, packagePath.isEmpty, arguments.isEmpty else {
                throw .validationFailed(
                    reason:
                        "architecture validate or index takes only --workspace-path."
                )
            }
        } else {
            guard consumer.isEmpty, dependency.isEmpty else {
                throw .validationFailed(
                    reason:
                        "--consumer and --dependency are valid only with compose, restore, or verify."
                )
            }
            guard operation == .sync || !dry else {
                throw .validationFailed(
                    reason: "--dry-run is valid only with sync or inventory regenerate."
                )
            }
            guard modes.isEmpty else {
                throw .validationFailed(reason: "install and check are valid only after context.")
            }
            guard !fresh, packagePath.isEmpty, workspacePath.isEmpty else {
                throw .validationFailed(
                    reason: "--fresh, --package-path, and --workspace-path are not valid here."
                )
            }
            guard arguments.isEmpty else {
                throw .validationFailed(reason: "--argument is valid only with package.")
            }
        }
    }

    public mutating func run() async throws(Institute.Error) {
        if case .install = operation {
            let installation = try Institute.Installation()
            try installation.install()
            print("institute: installed and verified")
            print("institute command: \(installation.command)")
            print("institute executable: \(installation.executable)")
            return
        }

        if case .github = operation, modes.first == .token {
            // Minting a credential has nothing to do with a Institute
            // checkout, so this returns before any root is resolved: the
            // command works from any directory on the machine, which is what
            // makes `GH_TOKEN=$(institute github token --org X)` usable in a
            // lane standing inside a package.
            let app: GitHub.App
            let result: (token: GitHub.App.Token, cached: Swift.Bool)
            do throws(GitHub.App.Error) {
                app = try .resolve(
                    identity: applicationIdentity.isEmpty ? nil : applicationIdentity,
                    keyPath: keyPath.isEmpty ? nil : keyPath,
                    // The sole Institute-specific residue of the extracted
                    // mechanism: the name of the directory under ~/.config
                    // where this operator keeps the bot's credentials.
                    configurationDirectoryName: "swift-institute-bot"
                )
                result = try app.token(
                    organization: organization,
                    permissions: try permissions.map { value throws(GitHub.App.Error) in
                        try .init(argument: value)
                    }
                )
            } catch {
                throw .configuration("github token: \(error)")
            }
            // The token is the whole of stdout, with no trailing commentary,
            // so command substitution captures a credential and nothing else.
            // Everything a human wants to know goes to stderr, where it cannot
            // end up inside an Authorization header.
            print(result.token.value)
            printToStandardError(
                "github token: \(result.cached ? "cache hit" : "minted") for \(organization)\n"
            )
            return
        }

        guard let working = Environment.read("PWD") else {
            throw .configuration("PWD is not available")
        }

        if case .architecture = operation {
            try architecture(
                mode: modes.first,
                path: workspacePath.isEmpty ? working : workspacePath
            )
        }

        if case .package = operation, modes.first == .lint {
            // The inner-loop path. It reads no inventory, enumerates no
            // organisation, and constructs no `Institute.Root`: standing
            // inside a package, the package root and the installed
            // binaries are both reachable by walking up. That is what
            // keeps this mode from paying ecosystem-scale costs.
            let target = try Institute.Lint.Target.resolve(
                packagePath.isEmpty ? working : packagePath
            )
            let lint = try Institute.Lint.resolve(from: target.package.description)
            // The default bundle comes from where the package sits under
            // the hierarchy the installation was found in — the same
            // ascent, no extra reads. It is used only when the package
            // carries no `Lint.swift`.
            let installation = try lint.installation()
            let mode: Institute.Lint.Fix? = fix ? (dry ? .dryRun : .apply) : nil
            if mode != nil {
                guard Institute.Lint.supportsFix(installation) else {
                    throw .configuration(Institute.Lint.fixUnsupported)
                }
                // A refusal is reported as a measurement, never thrown.
                // Thrown, it left the report entirely: a lane saw
                // swift-format clean, swiftlint clean, and no swift-linter
                // line at all, and absence of a finding read as absence of
                // findings. As an UNMEASURED verdict it occupies the same
                // line, the same word, and the same exit code as every
                // other run that established nothing.
                if let reason = try lint.currency().reason {
                    let refused = Institute.Lint.Measurement(
                        package: target.package.description,
                        verdict: .unmeasured(reason: reason),
                        summary: nil,
                        plan: nil,
                        findings: [],
                        structured: nil,
                        prerequisite: .currency,
                        diagnostics: "",
                        status: 0
                    )
                    print(refused)
                    Process.Exit.normal(2)
                }
                // The shadow gate, first tier only. The inner loop stands
                // inside one package and reads no inventory, so the
                // re-export tier — which needs the population to resolve a
                // module to the package providing it — has nothing to
                // resolve against and is not attempted. The sweep is where
                // it runs, and the sweep is what dispatches the fleet.
                let exclusions: [Swift.String]
                if let exclusion = Institute.Lint.Shadow.exclusion(
                    for: Institute.Lint.Shadow.scan(target.package)
                ) {
                    print("\(exclusion)")
                    print(
                        "          PLAT-ARCH-022 qualification is unsound here; "
                            + "it is excluded while other safe fixes proceed"
                    )
                    exclusions = [Institute.Lint.Fix.shadowedStandardLibraryQualification]
                } else {
                    exclusions = []
                }
                let measurement = lint.measure(
                    target,
                    using: installation,
                    default: Institute.Lint.Bundle.resolve(
                        target.package,
                        under: lint.hierarchy
                    ),
                    fix: mode,
                    excluding: exclusions
                )
                print(measurement)
                Process.Exit.normal(
                    measurement.verdict.fails ? (measurement.verdict.isUnmeasured ? 2 : 1) : 0
                )
            }
            let measurement = lint.measure(
                target,
                using: installation,
                default: Institute.Lint.Bundle.resolve(
                    target.package,
                    under: lint.hierarchy
                ),
                fix: mode
            )
            print(measurement)
            Process.Exit.normal(
                measurement.verdict.fails ? (measurement.verdict.isUnmeasured ? 2 : 1) : 0
            )
        }

        if case .package = operation, modes.first == .check {
            // The local CI-parity gate. Same inner-loop ascent as
            // `package lint`: no inventory, no `Institute.Root`, just
            // the package root and the installed swift-linter reached
            // by walking up from wherever the caller stands.
            let target = try Institute.Lint.Target.resolve(
                packagePath.isEmpty ? working : packagePath
            )
            let lint = try Institute.Lint.resolve(from: target.package.description)
            let check = Institute.Lint.Check(lint)
            let report = check.run(target, jobs: jobs, fresh: fresh)
            print(report)
            Process.Exit.normal(report.fails ? 1 : 0)
        }

        if case .package = operation {
            guard let action = modes.first?.buildAction else {
                throw .configuration("package operation was not provided")
            }
            let status: Swift.Int32
            do throws(Build.Error) {
                status = try Build.Coordinator(jobs: jobs).run(
                    action,
                    at: packagePath.isEmpty ? working : packagePath,
                    fresh: fresh,
                    arguments: arguments
                )
            } catch {
                throw .process("\(error)")
            }
            Process.Exit.normal(status)
        }

        if case .verification = operation {
            switch modes.first {
            case .some(.seal):
                let subjectPath = packagePath.isEmpty ? working : packagePath
                let remote: Swift.String
                do throws(Git.Client.Error) {
                    remote = try Git.Client().remote("origin", at: subjectPath)
                } catch {
                    throw .process(
                        "cannot read the subject's origin remote at \(subjectPath): \(error)"
                    )
                }
                guard let coordinate = Institute.Repository.Key(url: remote) else {
                    throw .configuration(
                        "origin remote \(remote) is not a canonical https://github.com/owner/name.git URL"
                    )
                }
                // `validate()` already refused every invalid combination;
                // this reconstructs the typed value it validated.
                let verificationInventoryDigest: Institute.Verification.Inventory.Digest
                do throws(Institute.Verification.Inventory.Digest.Error) {
                    verificationInventoryDigest = try .init(
                        token: inventoryDigest,
                        cause: inventoryDigestCause.isEmpty ? nil : inventoryDigestCause
                    )
                } catch {
                    throw .configuration("verification seal: \(error)")
                }
                let requested =
                    requestedOperations.isEmpty
                    ? [Institute.Verification.Operation.Kind.build, .test, .lint]
                    : requestedOperations.compactMap(
                        Institute.Verification.Operation.Kind.init(rawValue:)
                    )
                let required =
                    requiredOperations.isEmpty
                    ? requested
                    : requiredOperations.compactMap(
                        Institute.Verification.Operation.Kind.init(rawValue:)
                    )

                let run = Institute.Verification.Run(
                    packagePath: subjectPath,
                    claimedHead: claimedHead,
                    coordinate: coordinate,
                    // `validate()` already refused an unrecognised value.
                    visibility: Institute.Verification.Visibility(
                        rawValue: verificationVisibility
                    )!,
                    defaultBranch: defaultBranch,
                    layer: Institute.Layer(rawValue: verificationLayer)!,
                    inventoryDigest: verificationInventoryDigest,
                    workspaceRevision: workspaceRevision,
                    policyRevision: policyRevision,
                    requestedOperations: requested,
                    requiredOperations: required,
                    platformSupport: platformSupport,
                    fresh: fresh,
                    jobs: jobs,
                    arguments: arguments
                )
                let receipt: Institute.Verification.Receipt
                do throws(Institute.Verification.Error) {
                    receipt = try run.run()
                } catch {
                    throw .configuration("verification seal: \(error)")
                }

                let outputPath: File.Path
                do throws(File.Path.Error) {
                    outputPath = try File.Path(receiptPath)
                } catch {
                    throw .configuration("invalid --receipt path \(receiptPath): \(error)")
                }
                guard !File(outputPath).stat.exists else {
                    throw .configuration(
                        "--receipt \(receiptPath) already exists; verification seal writes only a "
                            + "newly created output path"
                    )
                }
                let outputFile = File(outputPath)
                // Untyped catch, deliberately: the async `atomic(_:options:)`
                // overload throws `Either<Kernel.Thread.Pool.Error,
                // File.System.Write.Atomic.Error>`, whose first member this
                // file has no reason to name or depend on directly — this
                // call site only needs "did the write succeed," which an
                // untyped `catch` reports exactly as well as spelling out
                // the union would.
                do {
                    try await outputFile.write.atomic(receipt.canonical)
                } catch {
                    throw .configuration("cannot write --receipt \(receiptPath): \(error)")
                }
                let summaryLine =
                    "verification seal: \(receipt.subject.coordinate.identity) "
                    + "\(receipt.verdict.fails ? "unverified" : "verified"), "
                    + "\(receipt.operations.count) operation(s)"
                    + ", digest \(receipt.digest)" + "\n"
                printToStandardError(summaryLine)
                Process.Exit.normal(receipt.verdict.fails ? 1 : 0)

            case .some(.check):
                let inputPath: File.Path
                do throws(File.Path.Error) {
                    inputPath = try File.Path(receiptPath)
                } catch {
                    throw .configuration("invalid --receipt path \(receiptPath): \(error)")
                }
                let bytes: [Byte]
                do throws(Either<File.System.Read.Full.Error, Never>) {
                    bytes = try File.System.Read.Full.read(from: inputPath) {
                        (span: Swift.Span<Byte>) in
                        var storage = [Byte]()
                        storage.reserveCapacity(span.count)
                        for index in span.indices {
                            storage.append(span[index])
                        }
                        return storage
                    }
                } catch {
                    throw .configuration("cannot read --receipt \(receiptPath): \(error)")
                }
                let receipt: Institute.Verification.Receipt
                do throws(JSON.Error) {
                    receipt = try .init(
                        jsonString: Swift.String(decoding: bytes, as: Swift.UTF8.self)
                    )
                } catch {
                    throw .configuration("cannot decode --receipt \(receiptPath): \(error)")
                }
                let diagnostics = Institute.Verification.Check.diagnostics(for: receipt)
                guard diagnostics.isEmpty else {
                    throw .configuration(diagnostics.joined(separator: "\n"))
                }
                print(
                    "verification: current — \(receipt.subject.coordinate.identity) consistent"
                        + ", digest \(receipt.digest)"
                )

            default:
                throw .configuration("verification operation must be seal or check")
            }
            return
        }

        let checkoutValue =
            (operation == .navigation || operation == .lint) && !workspacePath.isEmpty
            ? workspacePath
            : working
        let checkout: File.Directory
        do throws(File.Path.Error) {
            checkout = try File.Directory(validating: checkoutValue)
        } catch {
            throw .configuration("Institute checkout is not a valid path: \(error)")
        }
        let root = try Institute.Root(checkout: checkout)

        if case .lint = operation {
            let lint = Institute.Lint(root: root)
            switch modes.first {
            case .some(.install):
                // Install the installation `--fix` would resolve, not the
                // one this process happens to be standing next to. The two
                // rules disagreed — `--fix` ascends from the linted package,
                // `install` took the cwd's parent — so an install run from
                // anywhere else refreshed a different tree and reported
                // success while the lint run kept refusing on the tree it
                // had actually reached. Falling back to the checkout-derived
                // hierarchy keeps the first install on a fresh machine
                // working, where there is no installation to ascend to.
                let target = Institute.Lint.existing(from: checkoutValue) ?? lint
                try target.install()
                let manifest = try target.installedManifest()
                print("lint: installed swift-linter \(manifest.digest)")
                print("lint: \(try target.executable(for: manifest))")
                // Always name the installation that was written. A success
                // line that does not say *which* installation is exactly
                // what let eight consecutive successful installs leave the
                // refusing tree untouched.
                print("lint: installation \(target.manifestFile)")

            case .some(.check):
                let diagnostics = try lint.diagnostics()
                guard diagnostics.isEmpty else {
                    throw .configuration(diagnostics.joined(separator: "\n"))
                }
                print("lint: current — digest \(try lint.installedManifest().digest) matches CI")

            case .some(.ledger):
                let dispositions = self.dispositions.compactMap(
                    Institute.Lint.Ledger.Disposition.init(argument:)
                )
                let verifications = self.verifications.compactMap(
                    Institute.Lint.Ledger.Verification.init(argument:)
                )
                let configuration = try Institute.Configuration.load(at: root.checkout)
                let report = try await Institute.Lint.Sweep(
                    lint: lint,
                    root: root,
                    repositories: configuration.repositories
                ).ledger(dispositions: dispositions, verifications: verifications)
                switch output ?? .human {
                case .human: print(report.description, terminator: "")
                case .json: print(report.json, terminator: "")
                }
                Process.Exit.normal(report.status)

            case nil:
                let fixMode: Institute.Lint.Fix? = fix ? (dry ? .dryRun : .apply) : nil
                if fixMode != nil {
                    guard Institute.Lint.supportsFix(try lint.installation()) else {
                        throw .configuration(Institute.Lint.fixUnsupported)
                    }
                    // Same discipline as the single-package path: the
                    // sweep refuses in the sweep's own vocabulary rather
                    // than as a thrown error, so a reader scanning for
                    // UNMEASURED finds it and an exit code of 2 separates
                    // it from both 0 (clean) and 1 (violations).
                    if let reason = try lint.currency().reason {
                        print("lint all: UNMEASURED — \(reason)")
                        print(
                            "lint all: 0 packages linted; no repository in this sweep has been "
                                + "measured, and none may be recorded clean"
                        )
                        Process.Exit.normal(2)
                    }
                }
                let configuration = try Institute.Configuration.load(at: root.checkout)
                let report = try await Institute.Lint.Sweep(
                    lint: lint,
                    root: root,
                    repositories: configuration.repositories
                ).run(scope: changed ? .changed : .all, fix: fixMode)
                print(report)
                Process.Exit.normal(report.status)

            default:
                throw .configuration("lint operation must be install, check, ledger, or absent")
            }
            return
        }

        if case .navigation = operation {
            switch modes.first {
            case .some(.install):
                let configuration = try Institute.Configuration.load(at: root.checkout)
                let navigation = Institute.Navigation(
                    root: root,
                    configuration: configuration
                )
                try navigation.install()
                print("navigation: installed and verified")
                print("navigation MCP descriptor: \(navigation.descriptorFile)")

            case .some(.check):
                let configuration = try Institute.Configuration.load(at: root.checkout)
                let navigation = Institute.Navigation(
                    root: root,
                    configuration: configuration
                )
                let diagnostics = try navigation.diagnostics()
                guard diagnostics.isEmpty else {
                    throw .configuration(diagnostics.joined(separator: "\n"))
                }
                print("navigation: current")

            case .some(.serve):
                try Institute.Navigation.serve()

            case nil:
                throw .configuration("navigation operation was not provided")

            default:
                throw .configuration("navigation operation must be install, check, or serve")
            }
            return
        }

        if case .context = operation {
            let context = try Institute.Context(root: root)
            switch modes.first {
            case .some(.install):
                print(try context.install().summary)

            case .some(.check):
                let diagnostics = try context.diagnostics()
                guard diagnostics.isEmpty else {
                    throw .configuration(diagnostics.joined(separator: "\n"))
                }
                print("context: current")

            case .some(.packet):
                guard let key = Institute.Context.Packet.Key(argument: issue) else {
                    throw .configuration("context packet requires --issue owner/repository#N.")
                }
                let result = await Institute.Context.Packet.Remote.client().record(
                    key,
                    includedComments
                )
                let report: Institute.Context.Packet.Report
                switch result {
                case .available(let record):
                    report = .init(record: record, diagnostics: [], maxBytes: maxBytes)

                case .unavailable(let reason), .malformed(let reason), .unmeasured(let reason):
                    report = .init(record: nil, diagnostics: [reason], maxBytes: maxBytes)
                }
                let format: Institute.Context.Packet.Output
                switch output {
                case .some(.json): format = .json
                case .some(.human), nil: format = .human
                }
                print(report.render(format), terminator: "")
                Process.Exit.normal(report.status)

            case nil:
                throw .configuration("context operation was not provided")

            default:
                throw .configuration("context operation must be install, check, or packet")
            }
            return
        }

        let configuration = try Institute.Configuration.load(at: root.checkout)
        switch operation {
        case .install:
            return

        case .sync:
            let selection = try Institute.Selection.effective(at: root.checkout, in: configuration)
            try Institute.Sync(root: root, selection: selection).run(dry: dry)

        case .build:
            let selection = try Institute.Selection.effective(at: root.checkout, in: configuration)
            print(selection.origin)
            let status = try Institute.Xcode.Build(root: root, selection: selection)
                .run(fresh: fresh, arguments: arguments)
            Process.Exit.normal(status)

        case .doctor:
            let selection = try Institute.Selection.effective(at: root.checkout, in: configuration)
            let registry = try Institute.Peer.Registry.load(at: root.checkout)
            let report = await Institute.Doctor(
                root: root,
                configuration: configuration,
                selection: selection,
                peers: registry.peers,
                progress: .standardOutput
            ).run(access: institute ? .institute() : .contributor)
            print(report)
            Process.Exit.normal(report.status)

        case .coherence:
            let selection = try Institute.Selection.effective(at: root.checkout, in: configuration)
            print(selection.origin)
            let receipt = await Institute.Coherence.Run(
                root: root,
                configuration: configuration,
                selection: selection,
                buildPath: buildPath ?? .xcodebuildMerged
            ).run()
            print(receipt.canonical)
            print(
                "coherence: verdict \(receipt.verdict.rawValue), digest \(receipt.digest)"
            )
            Process.Exit.normal(receipt.verdict.status)

        case .certification:
            if modes.first == .run {
                let bytes: [Byte]
                let validated: File.Path
                do throws(File.Path.Error) {
                    validated = try File.Path(receiptPath)
                } catch {
                    throw .configuration("invalid --receipt path \(receiptPath): \(error)")
                }
                do throws(Either<File.System.Read.Full.Error, Never>) {
                    bytes = try File.System.Read.Full.read(from: validated) {
                        (span: Swift.Span<Byte>) in
                        var storage = [Byte]()
                        storage.reserveCapacity(span.count)
                        for index in span.indices { storage.append(span[index]) }
                        return storage
                    }
                } catch {
                    throw .configuration("cannot read snapshot at \(receiptPath): \(error)")
                }
                let snapshot: Institute.Certification.Snapshot
                do {
                    snapshot = try Institute.Certification.Snapshot(
                        jsonString: Swift.String(decoding: bytes, as: Swift.UTF8.self)
                    )
                } catch {
                    throw .configuration("snapshot does not decode: \(error)")
                }

                let platform: Institute.Certification.Platform =
                    switch Institute.Coherence.Run.currentPlatform {
                    case "macos": .macos
                    case "windows": .windows
                    default: .linux
                    }
                let policy: Institute.Certification.Policy
                do {
                    policy = try .init(platforms: [platform], quality: [])
                } catch {
                    throw .configuration("cannot form canary policy: \(error)")
                }
                var obligations = Institute.Certification.Obligation.derive(
                    from: snapshot,
                    policy: policy
                )
                if !arguments.isEmpty {
                    let selected = Set(arguments)
                    obligations = obligations.filter { selected.contains($0.key.identity) }
                }
                let accounts: [Institute.Certification.Account]
                if fresh {
                    // Ephemeral exact-revision evaluation: clone each member
                    // from its local materialization, prove the clone is at
                    // the snapshot revision, fresh-resolve so internal edges
                    // pin current tips (= snapshot at freeze time), execute,
                    // read closure, delete. No shared tree is mutated.
                    accounts = Self.ephemeralAccounts(
                        obligations: obligations,
                        snapshot: snapshot,
                        root: root,
                        configuration: configuration,
                        platform: platform
                    )
                } else {
                    let execution = Institute.Certification.Execution(
                        root: root,
                        configuration: configuration,
                        platform: platform
                    )
                    accounts = execution.accounts(for: obligations, in: snapshot)
                }
                for account in accounts {
                    print(account.json.serialize(sortKeys: true))
                }
                // Law-2 closure coverage: read back each selected member's
                // resolved state and classify every governed edge. Under
                // --fresh the ephemeral evaluator already emitted coverage
                // from each clone's own resolution.
                var repositories = [Swift.String: Institute.Repository]()
                for repository in configuration.repositories {
                    repositories["\(repository.organization)/\(repository.name)"] =
                        repository
                }
                let packages = Package.Manager()
                var coverageFailures = fresh ? Self.ephemeralCoverageFailures : 0
                for identity in fresh ? [] : Set(accounts.map(\.obligation.key)) {
                    guard let repository = repositories[identity.identity] else { continue }
                    let directory: File.Directory
                    do throws(Institute.Error) {
                        directory = try root.materialization(for: repository)
                    } catch {
                        printToStandardError(
                            "closure: \(identity.identity): no readable materialization — "
                                + "UNMEASURED\n"
                        )
                        coverageFailures += 1
                        continue
                    }
                    let resolution: Package.Resolution
                    do {
                        resolution = try packages.resolution(at: directory.description)
                    } catch {
                        printToStandardError(
                            "closure: \(identity.identity): resolution unreadable — "
                                + "UNMEASURED\n"
                        )
                        coverageFailures += 1
                        continue
                    }
                    let coverage = try Institute.Certification.Closure.Coverage(
                        consumer: identity,
                        proofs: Institute.Certification.Closure.proofs(
                            consumer: identity,
                            resolution: resolution,
                            snapshot: snapshot
                        )
                    )
                    print(coverage.json.serialize(sortKeys: true))
                    if !coverage.passes { coverageFailures += 1 }
                }
                let met = accounts.filter {
                    if case .met = $0.outcome { true } else { false }
                }.count
                let failed = accounts.filter {
                    if case .failed = $0.outcome { true } else { false }
                }.count
                printToStandardError(
                    "certification run: \(accounts.count) obligations, \(met) met, "
                        + "\(failed) failed, \(accounts.count - met - failed) unmeasured, "
                        + "\(coverageFailures) closure failures\n"
                )
                Process.Exit.normal(
                    failed == 0 && met == accounts.count && coverageFailures == 0 ? 0 : 1
                )
            }
            let git = Git.Client()
            let inventoryCommit: Institute.Certification.Revision
            let inventoryBlob: Swift.String
            var centrals = [Institute.Repository.Key: Institute.Certification.Revision]()
            var reading = root.checkout.description
            do {
                inventoryCommit = try .init(
                    git.head("HEAD", at: root.checkout.description).rawValue
                )
                inventoryBlob = try git.head(
                    "HEAD:Institute.json",
                    at: root.checkout.description
                ).rawValue
                // The control-plane member set named on
                // swift-institute/.github#600 (2026-08-18 population
                // reconciliation): governance repositories certified by
                // exact revision, never by implied package obligations.
                for name in [
                    ".github", "institute", "institute-application",
                    "institute-continuous-integration", "Issues", "Research",
                    "swift-institute.org",
                ] {
                    reading = "\(root.hierarchy)/\(name)"
                    guard
                        let key = Institute.Repository.Key(
                            identity: "swift-institute/\(name)"
                        )
                    else {
                        throw Institute.Error.repository(
                            "swift-institute/\(name) is not a canonical repository key"
                        )
                    }
                    centrals[key] = try .init(
                        git.head("main", at: "\(root.hierarchy)/\(name)").rawValue
                    )
                }
            } catch {
                throw .configuration(
                    "certification snapshot: cannot read exact heads at \(reading): \(error)"
                )
            }
            let snapshot = try Institute.Certification.Derivation(
                root: root,
                configuration: configuration
            ).snapshot(
                inventoryCommit: inventoryCommit,
                inventoryBlob: inventoryBlob,
                centrals: centrals,
                exclusions: []
            )
            print(snapshot.canonical)
            printToStandardError(
                "certification snapshot: \(snapshot.members.count) members, "
                    + "\(snapshot.exclusions.count) exclusions, digest \(snapshot.digest)\n"
            )
            Process.Exit.normal(0)

        case .conversion:
            switch modes.first {
            case .some(.seal):
                let selection = try Institute.Selection.effective(
                    at: root.checkout,
                    in: configuration
                )
                let receipt = try await Institute.Conversion.Seal(root: root, selection: selection)
                    .run()
                print(receipt.canonical)
                let summaryLine =
                    "conversion seal: \(receipt.cohort.count) repositories, "
                    + "\(receipt.pages.count) pages"
                    + ", digest \(receipt.digest)" + "\n"
                printToStandardError(summaryLine)

            case .some(.check):
                let validated: File.Path
                do throws(File.Path.Error) {
                    validated = try File.Path(receiptPath)
                } catch {
                    throw .configuration("invalid --receipt path \(receiptPath): \(error)")
                }
                let bytes: [Byte]
                do throws(Either<File.System.Read.Full.Error, Never>) {
                    bytes = try File.System.Read.Full.read(from: validated) {
                        (span: Swift.Span<Byte>) in
                        var storage = [Byte]()
                        storage.reserveCapacity(span.count)
                        for index in span.indices {
                            storage.append(span[index])
                        }
                        return storage
                    }
                } catch {
                    throw .configuration("cannot read --receipt \(receiptPath): \(error)")
                }
                let receipt: Institute.Conversion.Receipt
                do throws(JSON.Error) {
                    receipt = try .init(
                        jsonString: Swift.String(decoding: bytes, as: Swift.UTF8.self)
                    )
                } catch {
                    throw .configuration("cannot decode --receipt \(receiptPath): \(error)")
                }
                let diagnostics = Institute.Conversion.Check.diagnostics(for: receipt, root: root)
                guard diagnostics.isEmpty else {
                    throw .configuration(diagnostics.joined(separator: "\n"))
                }
                print("conversion: current — \(receipt.cohort.count) repositories consistent")

            default:
                throw .configuration("conversion operation must be seal or check")
            }

        case .inventory:
            switch modes.first {
            case nil:
                print(
                    Institute.Inventory.Register(
                        repositories: configuration.repositories
                    )
                )
                let registry = try Institute.Peer.Registry.load(at: root.checkout)
                for peer in registry.peers {
                    let presence: Institute.Peer.Presence
                    do throws(Institute.Error) {
                        presence = .resolve(peer, at: try root.peer(peer))
                    } catch {
                        presence = .invalid("\(error)")
                    }
                    print(Institute.Peer.Report(peer: peer, presence: presence))
                }

            case .some(.regenerate):
                let document = try Institute.Configuration.Document.load(at: root.checkout)
                let http = GitHub.HTTP.Client<
                    Institute.Inventory.Transport.Error,
                    GitHub.HTTP.Pagination.Error
                >(
                    agent: .init(rawValue: "swift-institute-workspace"),
                    version: .init(rawValue: "2022-11-28"),
                    execute: Institute.Inventory.Transport.githubCLI()
                )
                let application = Institute.Inventory.Application(
                    root: root.checkout,
                    policy: .institute(),
                    // `gh` supplies the credential; see Institute.Inventory.Transport.
                    client: Institute.Inventory.client(
                        http,
                        authentication: .token(.init(rawValue: ""))
                    )
                )
                let plan: Institute.Inventory.Writer.Plan
                do {
                    plan = try await application.run(existing: document, dry: dry)
                } catch {
                    throw .configuration("inventory regenerate: \(error)")
                }
                switch plan {
                case .current:
                    print("inventory regenerate: Institute.json is current")

                case .replace:
                    print(
                        dry
                            ? "inventory regenerate: would replace Institute.json"
                            : "inventory regenerate: replaced Institute.json"
                    )
                }

            case .some(.effective):
                guard
                    let scope = Institute.Inventory.Effective.Output.Scope(rawValue: inventoryScope)
                else {
                    throw .configuration(
                        "inventory effective: --inventory-scope must be public or effective"
                    )
                }
                guard !inventoryOutput.isEmpty else {
                    throw .configuration("inventory effective: --inventory-output is required")
                }
                let outputPath: File.Path
                do throws(File.Path.Error) {
                    outputPath = try File.Path(inventoryOutput)
                } catch {
                    throw .configuration(
                        "inventory effective: --inventory-output is not a valid path: \(error)"
                    )
                }

                // A supplied roster replaces the live pass entirely: the
                // caller holds credentials this process does not (per-org
                // App installation tokens), so it discovers and this
                // process digests. Refused under `--inventory-scope
                // public`, where there is no private limb to supply.
                if !inventoryPrivateRoster.isEmpty {
                    guard scope == .effective else {
                        throw .configuration(
                            "inventory effective: --inventory-private-roster requires "
                                + "--inventory-scope effective."
                        )
                    }
                    let rosterPath: File.Path
                    do throws(File.Path.Error) {
                        rosterPath = try File.Path(inventoryPrivateRoster)
                    } catch {
                        throw .configuration(
                            "inventory effective: --inventory-private-roster is not a valid path: "
                                + "\(error)"
                        )
                    }
                    let roster: Institute.Inventory.Effective.Roster
                    do throws(Institute.Inventory.Effective.Roster.Error) {
                        roster = try .read(rosterPath)
                    } catch {
                        throw .configuration("inventory effective: \(error)")
                    }
                    let supplied: Institute.Inventory.Effective
                    do throws(Institute.Inventory.Effective.Error) {
                        supplied = try .init(
                            public: configuration,
                            roster: roster,
                            policy: .institute()
                        )
                    } catch {
                        throw .configuration("inventory effective: \(error)")
                    }
                    let report = Institute.Inventory.Effective.Output(
                        scope: scope,
                        effective: supplied,
                        residue: roster.unmeasured
                    )
                    try report.write(to: outputPath)
                    let summary =
                        "inventory effective: scope \(scope.rawValue) from a supplied roster, "
                        + "\(report.combined.population.count) combined, "
                        + "\(report.unmeasured.count) unmeasured, wrote \(outputPath)\n"
                    printToStandardError(summary)
                    Process.Exit.normal(report.exitCode)
                }

                let discovery: Institute.Inventory.Private.Discovery
                switch scope {
                case .public:
                    // No private pass was requested; the report records the
                    // limb as not-requested rather than as an empty
                    // measurement.
                    discovery = .init(repositories: [], exclusions: [], unmeasured: [])

                case .effective:
                    let http = GitHub.HTTP.Client<
                        Institute.Inventory.Transport.Error,
                        GitHub.HTTP.Pagination.Error
                    >(
                        agent: .init(rawValue: "swift-institute-workspace"),
                        version: .init(rawValue: "2022-11-28"),
                        execute: Institute.Inventory.Transport.githubCLI()
                    )
                    let client = Institute.Inventory.client(
                        http,
                        // `gh` supplies the credential; see Institute.Inventory.Transport.
                        authentication: .token(.init(rawValue: ""))
                    )
                    do {
                        discovery = try await client.discoverPrivate(.institute())
                    } catch {
                        throw .configuration("inventory effective: \(error)")
                    }
                }

                let effective: Institute.Inventory.Effective
                do throws(Institute.Inventory.Effective.Error) {
                    effective = try .init(public: configuration, private: discovery)
                } catch {
                    throw .configuration("inventory effective: \(error)")
                }
                let report = Institute.Inventory.Effective.Output(
                    scope: scope,
                    effective: effective,
                    unmeasured: discovery.unmeasured
                )
                try report.write(to: outputPath)
                let summary =
                    "inventory effective: scope \(scope.rawValue), "
                    + "\(report.combined.population.count) combined, "
                    + "\(report.unmeasured.count) unmeasured, wrote \(outputPath)\n"
                printToStandardError(summary)
                Process.Exit.normal(report.exitCode)

            case .some(.pages):
                let selection = try Institute.Selection.effective(
                    at: root.checkout,
                    in: configuration
                )
                let inventory = await Institute.Pages.enumerate(root: root, selection: selection)
                print(inventory.canonical)
                let digest = inventory.digest
                let counts = inventory.nonCanonicalCounts
                let countsDescription =
                    counts.isEmpty
                    ? "0 non-canonical"
                    : counts.sorted { $0.key < $1.key }.map { "\($1) \($0)" }.joined(
                        separator: ", "
                    )
                        + " non-canonical"
                let summaryLine =
                    "inventory pages: \(inventory.repositories.count) repositories, "
                    + "\(countsDescription)"
                    + ", digest \(digest)" + "\n"
                printToStandardError(summaryLine)
                Process.Exit.normal(inventory.isFullyCanonical ? 0 : 1)

            default:
                throw .configuration(
                    "inventory operation must be regenerate, pages, effective, or absent"
                )
            }

        case .dependencies:
            let git = Git.Client()
            let head: Git.Object.ID
            let dirty: Swift.Bool
            do throws(Git.Client.Error) {
                head = try git.head(at: root.checkout.description)
                dirty = try git.status(at: root.checkout.description).contains {
                    $0.path == [UInt8]("Institute.json".utf8)
                }
            } catch {
                throw .process("cannot identify the Institute.json source revision: \(error)")
            }
            guard !dirty else {
                throw .configuration(
                    "Institute.json has working-tree changes; an exact source revision "
                        + "cannot be recorded"
                )
            }
            let exceptions = Set(
                sanctionedExceptions.compactMap(Institute.Repository.Key.init(identity:))
            )
            let report = await Institute.Dependency.Audit(
                repositories: configuration.repositories,
                policy: .institute(),
                client: Institute.Dependency.Remote.client(),
                sanctioned: exceptions,
                inventoryReference: "HEAD",
                inventoryRevision: head.rawValue
            ).run()
            switch output ?? .human {
            case .human: print(report)
            case .json: print(report.json, terminator: "")
            }
            Process.Exit.normal(report.status)

        case .compose:
            try Institute.Composition(root: root, configuration: configuration)
                .compose(consumer: consumer, dependency: dependency)

        case .restore:
            try Institute.Composition(root: root, configuration: configuration)
                .restore(consumer: consumer, dependency: dependency)

        case .verify:
            try Institute.Composition(root: root, configuration: configuration)
                .verify(consumer: consumer, dependency: dependency)

        case .context:
            return

        case .navigation:
            return

        case .package:
            return

        case .lint:
            return

        case .github:
            return

        case .verification:
            // Unreachable: `.verification` returns above, before `root`/
            // `configuration` are even resolved, exactly like `.package`.
            // Still a required arm — `Operation` gained a case, and every
            // exhaustive switch over it must account for that, whether or
            // not this arm can run.
            return

        case .architecture:
            // Unreachable: `.architecture` returns above, before `root`/
            // `configuration` are resolved, exactly like `.package`.
            return
        }
    }
}

extension Institute.Application.CLI {
    /// Removes an ephemeral evaluation directory. A failed removal is
    /// surfaced, never swallowed: leftover scratch is a disk-space defect,
    /// not an evaluation defect, so it must not fail an account.
    static func deleteEphemeral(at destination: Swift.String) {
        let path: File.Path
        do throws(File.Path.Error) {
            path = try File.Path(destination)
        } catch {
            return
        }
        do throws(File.System.Delete.Error) {
            try File.System.Delete.delete(at: path, recursive: true)
        } catch {
            printToStandardError("ephemeral: could not remove \(destination): \(error)\n")
        }
    }

    // Ephemeral exact-revision fleet evaluation state. `nonisolated(unsafe)`
    // is acceptable: the CLI dispatch is single-threaded per process.
    nonisolated(unsafe) static var ephemeralCoverageFailures = 0

    static func ephemeralAccounts(
        obligations: [Institute.Certification.Obligation],
        snapshot: Institute.Certification.Snapshot,
        root: Institute.Root,
        configuration: Institute.Configuration,
        platform: Institute.Certification.Platform
    ) -> [Institute.Certification.Account] {
        let git = Git.Client()
        let coordinator = Build.Coordinator()
        let packages = Package.Manager()
        var repositories = [Swift.String: Institute.Repository]()
        for repository in configuration.repositories {
            repositories["\(repository.organization)/\(repository.name)"] = repository
        }
        let scratch = "\(root.hierarchy)/.certifier-ephemeral"

        var accounts = [Institute.Certification.Account]()
        var byMember = [Institute.Repository.Key: [Institute.Certification.Obligation]]()
        for obligation in obligations {
            byMember[obligation.key, default: []].append(obligation)
        }

        for (key, owed) in byMember.sorted(by: { $0.key.identity < $1.key.identity }) {
            func account(_ outcome: Institute.Certification.Account.Outcome) {
                for obligation in owed {
                    accounts.append(.init(obligation: obligation, outcome: outcome))
                }
            }
            guard let member = snapshot[key] else {
                account(.failed(diagnostic: "\(key.identity): not an admitted snapshot member"))
                continue
            }
            guard let repository = repositories[key.identity] else {
                account(.failed(diagnostic: "\(key.identity): no inventory repository record"))
                continue
            }
            let source: File.Directory
            do throws(Institute.Error) {
                source = try root.materialization(for: repository)
            } catch {
                account(.unmeasured(reason: "\(key.identity): no readable materialization"))
                continue
            }
            let destination = "\(scratch)/\(repository.organization)__\(repository.name)"
            Self.deleteEphemeral(at: destination)
            do {
                try git.clone(source.description, branch: "main", to: destination)
            } catch {
                account(.unmeasured(reason: "\(key.identity): ephemeral clone failed: \(error)"))
                continue
            }
            defer { Self.deleteEphemeral(at: destination) }
            let head: Git.Object.ID
            do throws(Git.Client.Error) {
                head = try git.head("HEAD", at: destination)
            } catch {
                account(
                    .failed(
                        diagnostic: "\(key.identity): ephemeral head unreadable: \(error)"
                    )
                )
                continue
            }
            guard head.rawValue == member.revision.sha else {
                account(
                    .failed(
                        diagnostic: "\(key.identity): ephemeral clone is not the snapshot "
                            + "revision \(member.revision.sha)"
                    )
                )
                continue
            }
            // Re-pin the clone's committed Package.resolved to current
            // branch tips (= the snapshot at freeze time). Without this the
            // clone compiles whatever the member last committed — the exact
            // stale-pin class law 2 refuses.
            do {
                _ = try coordinator.run(
                    .update,
                    at: destination,
                    fresh: false,
                    arguments: [],
                    capturingDiagnostics: true
                )
            } catch {
                account(.unmeasured(reason: "\(key.identity): ephemeral update failed: \(error)"))
                continue
            }

            for obligation in owed {
                guard obligation.platform == platform else {
                    accounts.append(
                        .init(
                            obligation: obligation,
                            outcome: .unmeasured(
                                reason: "owed on \(obligation.platform.rawValue), this "
                                    + "execution measures \(platform.rawValue)"
                            )
                        )
                    )
                    continue
                }
                let action: Build.Action? =
                    switch obligation.kind {
                    case .build: .build
                    case .test: .test
                    case .lint, .format: nil
                    }
                guard let action else {
                    accounts.append(
                        .init(
                            obligation: obligation,
                            outcome: .unmeasured(
                                reason: "quality obligations are executed by the quality "
                                    + "instruments"
                            )
                        )
                    )
                    continue
                }
                let result: Build.Coordinator.Result
                do {
                    result = try coordinator.run(
                        action,
                        at: destination,
                        fresh: false,
                        arguments: [],
                        capturingDiagnostics: true
                    )
                } catch {
                    accounts.append(
                        .init(
                            obligation: obligation,
                            outcome: .unmeasured(reason: "coordinator error: \(error)")
                        )
                    )
                    continue
                }
                if result.exitCode == 0 {
                    accounts.append(
                        .init(
                            obligation: obligation,
                            outcome: .met(evidence: "ephemeral@\(member.revision.sha):exit:0")
                        )
                    )
                } else {
                    let captured =
                        Swift.String(
                            decoding: (result.standardOutput ?? []) + (result.standardError ?? []),
                            as: Swift.UTF8.self
                        )
                    let lines = captured.split(separator: "\n")
                    let diagnostic =
                        lines.first { $0.contains(": error:") }.map(Swift.String.init)
                        ?? lines.last(where: { !$0.isEmpty }).map(Swift.String.init)
                        ?? "failed with no captured diagnostic"

                    accounts.append(
                        .init(
                            obligation: obligation,
                            outcome: .failed(diagnostic: "\(key.identity): \(diagnostic)")
                        )
                    )
                }
            }

            let resolved: Package.Resolution?
            do throws(Package.Manager.Error) {
                resolved = try packages.resolution(at: destination)
            } catch {
                resolved = nil
            }
            if let resolution = resolved {
                do throws(Institute.Error) {
                    let coverage = try Institute.Certification.Closure.Coverage(
                        consumer: key,
                        proofs: Institute.Certification.Closure.proofs(
                            consumer: key,
                            resolution: resolution,
                            snapshot: snapshot
                        )
                    )
                    print(coverage.json.serialize(sortKeys: true))
                    if !coverage.passes { Self.ephemeralCoverageFailures += 1 }
                } catch {
                    printToStandardError(
                        "closure: \(key.identity): coverage refused — \(error) — UNMEASURED\n"
                    )
                    Self.ephemeralCoverageFailures += 1
                }
            } else {
                printToStandardError(
                    "closure: \(key.identity): ephemeral resolution unreadable — UNMEASURED\n"
                )
                Self.ephemeralCoverageFailures += 1
            }
        }
        return accounts
    }
}
