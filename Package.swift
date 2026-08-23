// swift-tools-version: 6.4

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
      name: "Institute Application Source",
      targets: ["Institute Application Source"]
    ),
    .library(
      name: "Institute Architecture Model",
      targets: ["Institute Architecture Model"]
    ),
    .library(
      name: "Institute Architecture Facts",
      targets: ["Institute Architecture Facts"]
    ),
    .library(
      name: "Institute Architecture Graph",
      targets: ["Institute Architecture Graph"]
    ),
    .library(
      name: "Institute Architecture Index",
      targets: ["Institute_Architecture_Index"]
    ),
    .library(
      name: "Institute Architecture Validation",
      targets: ["Institute Architecture Validation"]
    ),
    .library(
      name: "Institute Architecture Candidates",
      targets: ["Institute_Architecture_Candidates"]
    ),
    .library(
      name: "Institute Architecture Migration",
      targets: ["Institute Architecture Migration"]
    ),
    .library(
      name: "Institute Architecture CLI",
      targets: ["Institute Architecture CLI"]
    ),
    .executable(
      name: "institute",
      targets: ["Institute Application CLI"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/swift-institute/institute.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-agent-skills.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-arguments.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-async.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-environment.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-file-system.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-github.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-git.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-json.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-kernel.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-package-manager.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-console.git", branch: "main"),
    .package(
      url: "https://github.com/swift-foundations/swift-continuous-integration.git",
      branch: "main"
    ),
    .package(
      url: "https://github.com/swift-foundations/swift-github-continuous-integration.git",
      branch: "main"
    ),
    .package(url: "https://github.com/swift-foundations/swift-process.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-source.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-xcode.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-3986.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-4648.git", branch: "main"),
    .package(url: "https://github.com/swift-primitives/swift-byte-primitives.git", branch: "main"),
    .package(url: "https://github.com/swift-standards/swift-fips-180-4.git", branch: "main"),
    .package(url: "https://github.com/swift-standards/swift-github-standard.git", branch: "main"),
    .package(url: "https://github.com/swift-standards/swift-spm-standard.git", branch: "main"),
    .package(
      url: "https://github.com/swift-primitives/swift-standard-library-extensions.git",
      branch: "main"
    ),
  ],
  targets: [
    .target(
      name: "Institute Architecture Model",
      dependencies: [
        .product(name: "Institute Model", package: "institute")
      ]
    ),
    .target(
      name: "Institute Architecture Facts",
      dependencies: [
        "Institute Architecture Model",
        "Institute Architecture Graph",
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "JSON", package: "swift-json"),
      ]
    ),
    .target(
      name: "Institute Architecture Graph",
      dependencies: [
        "Institute Architecture Model",
        .product(name: "Institute Model", package: "institute"),
      ]
    ),
    .target(
      name: "Institute_Architecture_Index",
      dependencies: [
        "Institute Architecture Model",
        "Institute Architecture Graph",
        "Institute Architecture Facts",
        "Institute Architecture Validation",
        .product(name: "Institute Model", package: "institute"),
      ]
    ),
    .target(
      name: "Institute Architecture Validation",
      dependencies: [
        "Institute Architecture Model",
        "Institute Architecture Graph",
        "Institute Architecture Facts",
        .product(name: "Institute Model", package: "institute"),
      ]
    ),
    .target(
      name: "Institute_Architecture_Candidates",
      dependencies: [
        "Institute Architecture Model",
        .product(name: "Institute Model", package: "institute"),
      ]
    ),
    .target(
      name: "Institute Architecture Migration",
      dependencies: [
        "Institute Architecture Model",
        .product(name: "Institute Model", package: "institute"),
      ]
    ),
    .target(
      name: "Institute Architecture CLI",
      dependencies: [
        "Institute Architecture Model",
        "Institute Architecture Facts",
        "Institute Architecture Graph",
        "Institute_Architecture_Index",
        "Institute Architecture Validation",
        "Institute_Architecture_Candidates",
        "Institute Architecture Migration",
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Kernel", package: "swift-kernel"),
      ]
    ),
    .target(
      name: "Institute GitHub",
      dependencies: [
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Dependency", package: "institute"),
        .product(name: "GitHub", package: "swift-github"),
        .product(name: "JSON", package: "swift-json"),
        .product(name: "RFC 3986", package: "swift-rfc-3986"),
        .product(name: "RFC 4648", package: "swift-rfc-4648"),
      ]
    ),
    .target(
      name: "Institute Application Source",
      dependencies: [
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Source", package: "institute"),
        .product(name: "Institute Source Workspace", package: "institute"),
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "JSON", package: "swift-json"),
        .product(name: "Process", package: "swift-process"),
        .product(name: "Source Measurement", package: "swift-source"),
        .product(name: "Source Repair", package: "swift-source"),
        .product(name: "Source Report", package: "swift-source"),
      ]
    ),
    .target(
      name: "Institute Application",
      dependencies: [
        "Institute Application Source",
        .product(name: "Institute CI Canon", package: "institute"),
        .product(name: "Institute CI Contract", package: "institute"),
        .product(name: "Institute CI Inventory", package: "institute"),
        .product(name: "Institute CI Validation", package: "institute"),
        .product(name: "Institute Repository Policy", package: "institute"),
        .product(name: "Institute Build Coordinator", package: "institute"),
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
        "Institute Architecture Model",
        "Institute Architecture CLI",
        .product(name: "Skill Validation", package: "swift-agent-skills"),
        .product(name: "Async Fanout", package: "swift-async"),
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "GitHub", package: "swift-github"),
        .product(name: "GitHub App", package: "swift-github"),
        .product(name: "Git", package: "swift-git"),
        .product(name: "JSON", package: "swift-json"),
        .product(name: "Package Manager", package: "swift-package-manager"),
        .product(name: "Console", package: "swift-console"),
        .product(name: "Continuous Integration", package: "swift-continuous-integration"),
        .product(
          name: "GitHub Continuous Integration",
          package: "swift-github-continuous-integration"
        ),
        .product(
          name: "GitHub Continuous Integration Validation",
          package: "swift-github-continuous-integration"
        ),
        .product(name: "GitHub Standard", package: "swift-github-standard"),
        .product(name: "Process", package: "swift-process"),
        .product(name: "RFC 3986", package: "swift-rfc-3986"),
        .product(name: "RFC 4648", package: "swift-rfc-4648"),
        .product(name: "FIPS 180-4", package: "swift-fips-180-4"),
        .product(name: "SPM Standard", package: "swift-spm-standard"),
        .product(name: "Byte Primitives", package: "swift-byte-primitives"),
        .product(
          name: "Byte Primitives Standard Library Integration", package: "swift-byte-primitives"),
        .product(name: "Xcode Scheme", package: "swift-xcode"),
        .product(name: "Xcode Workspace", package: "swift-xcode"),
      ],
      path: "Sources/Institute Application"
    ),
    .executableTarget(
      name: "Institute Application CLI",
      dependencies: [
        .product(name: "Institute Build Coordinator", package: "institute"),
        "Institute Application",
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Command", package: "swift-arguments"),
      ]
    ),
    .testTarget(
      name: "InstituteArchitectureTests",
      dependencies: [
        "Institute Architecture Model",
        "Institute Architecture Facts",
        "Institute Architecture Graph",
        "Institute_Architecture_Index",
        "Institute Architecture Validation",
        "Institute_Architecture_Candidates",
        "Institute Architecture Migration",
        "Institute Architecture CLI",
        .product(name: "Institute Model", package: "institute"),
      ],
      path: "Tests/InstituteArchitectureTests"
    ),
    .testTarget(
      name: "Institute Application Source Tests",
      dependencies: [
        "Institute Application Source",
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Source", package: "institute"),
        .product(name: "Source Repair", package: "swift-source"),
      ]
    ),
    .testTarget(
      name: "Institute Application Tests",
      dependencies: [
        .product(name: "Institute Build Coordinator", package: "institute"),
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
        .product(name: "JSON", package: "swift-json"),
        .product(name: "SPM Standard", package: "swift-spm-standard"),
        .product(name: "Byte Primitives", package: "swift-byte-primitives"),
        .product(
          name: "Byte Primitives Standard Library Integration", package: "swift-byte-primitives"),
        .product(
          name: "Standard Library Extensions",
          package: "swift-standard-library-extensions"
        ),
      ],
      path: "Tests/Institute Application Tests"
    ),
    .testTarget(
      name: "Institute CI Command Tests",
      dependencies: [
        "Institute Application",
        .product(name: "Institute CI Validation", package: "institute"),
      ]
    ),
    .testTarget(
      name: "Institute Repository Policy Tests",
      dependencies: [
        "Institute Application",
        .product(name: "Institute Repository Policy", package: "institute"),
        .product(name: "Package Manager", package: "swift-package-manager"),
      ],
      resources: [.process("Fixtures")]
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
