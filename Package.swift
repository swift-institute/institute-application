// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "institute",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "Build Coordinator",
            targets: ["Build Coordinator"]
        ),
        .library(
            name: "Institute Model",
            targets: ["Institute Model"]
        ),
        .library(
            name: "Institute Inventory",
            targets: ["Institute Inventory"]
        ),
        .library(
            name: "Institute Dependency",
            targets: ["Institute Dependency"]
        ),
        .library(
            name: "Institute Development",
            targets: ["Institute Development"]
        ),
        .library(
            name: "Institute Lint",
            targets: ["Institute Lint"]
        ),
        .library(
            name: "Institute Pages",
            targets: ["Institute Pages"]
        ),
        .library(
            name: "Institute Doctor",
            targets: ["Institute Doctor"]
        ),
        .library(
            name: "Institute Conversion",
            targets: ["Institute Conversion"]
        ),
        .library(
            name: "Institute Instruments",
            targets: ["Institute Instruments"]
        ),
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
        .package(url: "https://github.com/swift-foundations/swift-agent-skills.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-arguments.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-async.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-environment.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-file-system.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-github.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-github-http.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-git.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-json.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-package-manager.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-posix.git", branch: "main"),
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
            name: "Build Coordinator",
            dependencies: [
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "POSIX Kernel Lock", package: "swift-posix"),
                .product(name: "Process", package: "swift-process"),
            ]
        ),
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
            ]
        ),
        .target(
            name: "Institute Model",
            dependencies: [
                .product(name: "Async Fanout", package: "swift-async"),
                .product(name: "Byte Primitives", package: "swift-byte-primitives"),
                .product(name: "FIPS 180-4", package: "swift-fips-180-4"),
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "Git", package: "swift-git"),
                .product(name: "GitHub", package: "swift-github"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "POSIX Kernel File", package: "swift-posix"),
                .product(name: "POSIX Kernel Lock", package: "swift-posix"),
                .product(name: "POSIX Kernel Process", package: "swift-posix"),
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
            ]
        ),
        .target(
            name: "Institute Inventory",
            dependencies: [
                "Institute Model",
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "Git", package: "swift-git"),
                .product(name: "GitHub", package: "swift-github"),
                .product(name: "GitHub HTTP", package: "swift-github-http"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "Process", package: "swift-process"),
            ]
        ),
        .target(
            name: "Institute Dependency",
            dependencies: [
                "Institute Model",
                "Institute Inventory",
                .product(name: "Async Fanout", package: "swift-async"),
                .product(name: "Byte Primitives", package: "swift-byte-primitives"),
                .product(
                    name: "Byte Primitives Standard Library Integration",
                    package: "swift-byte-primitives"
                ),
                .product(name: "Command", package: "swift-arguments"),
                .product(name: "GitHub", package: "swift-github"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "SPM Standard", package: "swift-spm-standard"),
            ]
        ),
        .target(
            name: "Institute Development",
            dependencies: [
                "Build Coordinator",
                "Institute Model",
                "Institute Inventory",
                .product(name: "Async Fanout", package: "swift-async"),
                .product(name: "Command", package: "swift-arguments"),
                .product(name: "Environment", package: "swift-environment"),
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "Git", package: "swift-git"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "POSIX Kernel Process", package: "swift-posix"),
                .product(name: "Package Manager", package: "swift-package-manager"),
                .product(name: "Process", package: "swift-process"),
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
                .product(name: "SPM Standard", package: "swift-spm-standard"),
                .product(name: "Skill Validation", package: "swift-agent-skills"),
                .product(name: "Xcode Scheme", package: "swift-xcode"),
                .product(name: "Xcode Workspace", package: "swift-xcode"),
            ]
        ),
        .target(
            name: "Institute Lint",
            dependencies: [
                "Institute Model",
                "Institute Development",
                .product(name: "Async Fanout", package: "swift-async"),
                .product(name: "Environment", package: "swift-environment"),
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "Git", package: "swift-git"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "Package Manager", package: "swift-package-manager"),
                .product(name: "Process", package: "swift-process"),
                .product(
                    name: "Standard Library Extensions",
                    package: "swift-standard-library-extensions"
                ),
            ]
        ),
        .target(
            name: "Institute Pages",
            dependencies: [
                "Institute Model",
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "JSON", package: "swift-json"),
            ]
        ),
        .target(
            name: "Institute Doctor",
            dependencies: [
                "Institute Model",
                "Institute Inventory",
                "Institute Pages",
                "Institute Development",
                "Institute Lint",
                .product(name: "Async Fanout", package: "swift-async"),
                .product(name: "Environment", package: "swift-environment"),
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "Git", package: "swift-git"),
                .product(name: "GitHub HTTP", package: "swift-github-http"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "Package Manager", package: "swift-package-manager"),
                .product(name: "Process", package: "swift-process"),
            ]
        ),
        .target(
            name: "Institute Conversion",
            dependencies: [
                "Institute Model",
                "Institute Pages",
                "Institute Doctor",
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "JSON", package: "swift-json"),
            ]
        ),
        .target(
            name: "Institute Instruments",
            dependencies: [
                "Build Coordinator",
                "Institute Model",
                "Institute Inventory",
                "Institute Development",
                "Institute Doctor",
                "Institute Lint",
                .product(name: "Command", package: "swift-arguments"),
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "Git", package: "swift-git"),
                .product(name: "GitHub", package: "swift-github"),
                .product(name: "JSON", package: "swift-json"),
            ]
        ),
        .target(
            name: "Institute GitHub",
            dependencies: [
                "Institute Model",
                "Institute Dependency",
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
                "Build Coordinator",
                "Institute Model",
                "Institute Inventory",
                "Institute Dependency",
                "Institute Development",
                "Institute Lint",
                "Institute Pages",
                "Institute Doctor",
                "Institute Conversion",
                "Institute Instruments",
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
                .product(name: "POSIX Kernel Process", package: "swift-posix"),
                .product(name: "Console", package: "swift-console"),
                .product(name: "POSIX Kernel File", package: "swift-posix"),
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
                "Build Coordinator",
                "Institute Application",
                "Institute Model",
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
                "Build Coordinator",
                "Institute Application",
                "Institute Model",
                "Institute Inventory",
                "Institute Dependency",
                "Institute Development",
                "Institute Lint",
                "Institute Pages",
                "Institute Doctor",
                "Institute Conversion",
                "Institute Instruments",
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
