// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "institute-application",
    platforms: [
        .macOS("27"),
        .iOS("27"),
        .tvOS("27"),
        .watchOS("27"),
        .visionOS("27"),
    ],
    products: [
        .library(
            name: "Institute GitHub",
            targets: ["Institute GitHub"]
        ),
        .library(
            name: "Institute Application",
            targets: ["Institute Application"]
        ),
        .library(
            name: "Institute Architecture Model",
            targets: ["InstituteArchitectureModel"]
        ),
        .library(
            name: "Institute Architecture Facts",
            targets: ["InstituteArchitectureFacts"]
        ),
        .library(
            name: "Institute Architecture Graph",
            targets: ["InstituteArchitectureGraph"]
        ),
        .library(
            name: "Institute Architecture Index",
            targets: ["InstituteArchitectureIndex"]
        ),
        .library(
            name: "Institute Architecture Validation",
            targets: ["InstituteArchitectureValidation"]
        ),
        .library(
            name: "Institute Architecture Candidates",
            targets: ["InstituteArchitectureCandidates"]
        ),
        .library(
            name: "Institute Architecture Migration",
            targets: ["InstituteArchitectureMigration"]
        ),
        .library(
            name: "Institute Architecture CLI",
            targets: ["InstituteArchitectureCLI"]
        ),
        .executable(
            name: "institute",
            targets: ["Institute Application CLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-institute/institute.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-agent-skills.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-arguments.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-async.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-environment.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-file-system.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-github.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-github-http.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-git.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-json.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-kernel.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-package-manager.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-console.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-process.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-xcode.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-3986.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-4648.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-byte-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-standards/swift-fips-180-4.git", branch: "main"),
        .package(url: "https://github.com/swift-standards/swift-spm-standard.git", branch: "main"),
        .package(
            url: "https://github.com/swift-primitives/swift-standard-library-extensions.git",
            branch: "main"
        )
    ],
    targets: [
        .target(
            name: "InstituteArchitectureModel"
        ),
        .target(
            name: "InstituteArchitectureFacts",
            dependencies: [
                "InstituteArchitectureModel",
                "InstituteArchitectureGraph",
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "JSON", package: "swift-json"),
            ]
        ),
        .target(
            name: "InstituteArchitectureGraph",
            dependencies: [
                "InstituteArchitectureModel"
            ]
        ),
        .target(
            name: "InstituteArchitectureIndex",
            dependencies: [
                "InstituteArchitectureModel",
                "InstituteArchitectureGraph",
                "InstituteArchitectureFacts",
                "InstituteArchitectureValidation",
            ]
        ),
        .target(
            name: "InstituteArchitectureValidation",
            dependencies: [
                "InstituteArchitectureModel",
                "InstituteArchitectureGraph",
                "InstituteArchitectureFacts",
            ]
        ),
        .target(
            name: "InstituteArchitectureCandidates",
            dependencies: [
                "InstituteArchitectureModel"
            ]
        ),
        .target(
            name: "InstituteArchitectureMigration",
            dependencies: [
                "InstituteArchitectureModel"
            ]
        ),
        .target(
            name: "InstituteArchitectureCLI",
            dependencies: [
                "InstituteArchitectureModel",
                "InstituteArchitectureFacts",
                "InstituteArchitectureGraph",
                "InstituteArchitectureIndex",
                "InstituteArchitectureValidation",
                "InstituteArchitectureCandidates",
                "InstituteArchitectureMigration",
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "Kernel", package: "swift-kernel"),
            ]
        ),
        .target(
            name: "Institute GitHub",
            dependencies: [
                .product(name: "Institute Model", package: "institute"),
                .product(name: "Institute Dependency", package: "institute"),
                .product(name: "GitHub", package: "swift-github"),
                .product(name: "GitHub HTTP", package: "swift-github-http"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
                .product(name: "RFC 4648", package: "swift-rfc-4648"),
            ]
        ),
        .target(
            name: "Institute Application",
            dependencies: [
                .product(name: "Build Coordinator", package: "institute"),
                .product(name: "Institute Model", package: "institute"),
                .product(name: "Institute Inventory", package: "institute"),
                .product(name: "Institute Dependency", package: "institute"),
                .product(name: "Institute Development", package: "institute"),
                .product(name: "Institute Lint", package: "institute"),
                .product(name: "Institute Pages", package: "institute"),
                .product(name: "Institute Doctor", package: "institute"),
                .product(name: "Institute Conversion", package: "institute"),
                .product(name: "Institute Instruments", package: "institute"),
                "Institute GitHub",
                "InstituteArchitectureCLI",
                .product(name: "Skill Validation", package: "swift-agent-skills"),
                .product(name: "Async Fanout", package: "swift-async"),
                .product(name: "Command", package: "swift-arguments"),
                .product(name: "Environment", package: "swift-environment"),
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "GitHub", package: "swift-github"),
                .product(name: "GitHub App", package: "swift-github"),
                .product(name: "GitHub HTTP", package: "swift-github-http"),
                .product(name: "Git", package: "swift-git"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "Package Manager", package: "swift-package-manager"),
                .product(name: "Console", package: "swift-console"),
                .product(name: "Process", package: "swift-process"),
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
                .product(name: "RFC 4648", package: "swift-rfc-4648"),
                .product(name: "FIPS 180-4", package: "swift-fips-180-4"),
                .product(name: "SPM Standard", package: "swift-spm-standard"),
                .product(name: "Byte Primitives", package: "swift-byte-primitives"),
                .product(name: "Byte Primitives Standard Library Integration", package: "swift-byte-primitives"),
                .product(name: "Xcode Scheme", package: "swift-xcode"),
                .product(name: "Xcode Workspace", package: "swift-xcode")
            ]
        ),
        .executableTarget(
            name: "Institute Application CLI",
            dependencies: [
                .product(name: "Build Coordinator", package: "institute"),
                "Institute Application",
                .product(name: "Institute Model", package: "institute"),
                .product(name: "Command", package: "swift-arguments")
            ]
        ),
        .testTarget(
            name: "InstituteArchitectureTests",
            dependencies: [
                "InstituteArchitectureModel",
                "InstituteArchitectureFacts",
                "InstituteArchitectureGraph",
                "InstituteArchitectureIndex",
                "InstituteArchitectureValidation",
                "InstituteArchitectureCandidates",
                "InstituteArchitectureMigration",
                "InstituteArchitectureCLI",
            ],
            path: "Tests/InstituteArchitectureTests"
        ),
        .testTarget(
            name: "Institute Application Tests",
            dependencies: [
                .product(name: "Build Coordinator", package: "institute"),
                "Institute Application",
                .product(name: "Institute Model", package: "institute"),
                .product(name: "Institute Inventory", package: "institute"),
                .product(name: "Institute Dependency", package: "institute"),
                .product(name: "Institute Development", package: "institute"),
                .product(name: "Institute Lint", package: "institute"),
                .product(name: "Institute Pages", package: "institute"),
                .product(name: "Institute Doctor", package: "institute"),
                .product(name: "Institute Conversion", package: "institute"),
                .product(name: "Institute Instruments", package: "institute"),
                "Institute GitHub",
                .product(name: "Skill Validation", package: "swift-agent-skills"),
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "GitHub", package: "swift-github"),
                .product(name: "GitHub HTTP", package: "swift-github-http"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "SPM Standard", package: "swift-spm-standard"),
                .product(name: "Byte Primitives", package: "swift-byte-primitives"),
                .product(name: "Byte Primitives Standard Library Integration", package: "swift-byte-primitives"),
                .product(
                    name: "Standard Library Extensions",
                    package: "swift-standard-library-extensions"
                ),
            ],
            path: "Tests/Institute Application Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        ]
}
