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
      name: "Institute Application CI",
      targets: ["Institute Application CI"]
    ),
    .library(
      name: "Institute Application Repository",
      targets: ["Institute Application Repository"]
    ),
    .library(
      name: "Institute Application Source",
      targets: ["Institute Application Source"]
    ),
    .library(
      name: "Institute Application Certification",
      targets: ["Institute Application Certification"]
    ),
    .library(
      name: "Institute Application Coherence",
      targets: ["Institute Application Coherence"]
    ),
    .library(
      name: "Institute Application Composition",
      targets: ["Institute Application Composition"]
    ),
    .library(
      name: "Institute Application Context",
      targets: ["Institute Application Context"]
    ),
    .library(
      name: "Institute Application Conversion",
      targets: ["Institute Application Conversion"]
    ),
    .library(
      name: "Institute Application Dependency",
      targets: ["Institute Application Dependency"]
    ),
    .library(
      name: "Institute Application Doctor",
      targets: ["Institute Application Doctor"]
    ),
    .library(
      name: "Institute Application GitHub",
      targets: ["Institute Application GitHub"]
    ),
    .library(
      name: "Institute Application Inventory",
      targets: ["Institute Application Inventory"]
    ),
    .library(
      name: "Institute Application Lint",
      targets: ["Institute Application Lint"]
    ),
    .library(
      name: "Institute Application Navigation",
      targets: ["Institute Application Navigation"]
    ),
    .library(
      name: "Institute Application Package",
      targets: ["Institute Application Package"]
    ),
    .library(
      name: "Institute Application Verification",
      targets: ["Institute Application Verification"]
    ),
    .library(
      name: "Institute Application Workspace",
      targets: ["Institute Application Workspace"]
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
      targets: ["Institute Architecture Index"]
    ),
    .library(
      name: "Institute Architecture Validation",
      targets: ["Institute Architecture Validation"]
    ),
    .library(
      name: "Institute Architecture Candidates",
      targets: ["Institute Architecture Candidates"]
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
    .package(url: "https://github.com/swift-foundations/swift-arguments.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-environment.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-file-system.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-github.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-git.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-json.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-kernel.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-paths.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-package-manager.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-console.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-4648.git", branch: "main"),
    .package(url: "https://github.com/swift-ietf/swift-rfc-3339.git", branch: "main"),
    .package(url: "https://github.com/swift-primitives/swift-time-primitives.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-process.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-source.git", branch: "main"),
    .package(url: "https://github.com/swift-primitives/swift-byte-primitives.git", branch: "main"),
    .package(url: "https://github.com/swift-standards/swift-fips-180-4.git", branch: "main"),
    .package(url: "https://github.com/swift-standards/swift-spm-standard.git", branch: "main"),
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
      name: "Institute Architecture Index",
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
      name: "Institute Architecture Candidates",
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
        "Institute Architecture Index",
        "Institute Architecture Validation",
        "Institute Architecture Candidates",
        "Institute Architecture Migration",
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Kernel", package: "swift-kernel"),
        .product(name: "Process", package: "swift-process"),
      ]
    ),
    .target(
      name: "Institute GitHub",
      dependencies: [
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Dependency", package: "institute"),
        .product(name: "Byte Primitives", package: "swift-byte-primitives"),
        .product(
          name: "Byte Primitives Standard Library Integration",
          package: "swift-byte-primitives"
        ),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "Process", package: "swift-process"),
      ]
    ),
    .target(
      name: "Institute Application CI",
      dependencies: [
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute CI Canon", package: "institute"),
        .product(name: "Institute Repository Policy", package: "institute"),
        .product(name: "Console", package: "swift-console"),
        .product(
          name: "Byte Primitives Standard Library Integration",
          package: "swift-byte-primitives"
        ),
        .product(name: "Institute CI Contract", package: "institute"),
        .product(name: "Institute CI Inventory", package: "institute"),
        .product(name: "Institute CI Model", package: "institute"),
        .product(name: "Institute CI Validation", package: "institute"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Byte Primitives", package: "swift-byte-primitives"),
        .product(name: "FIPS 180-4", package: "swift-fips-180-4"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "JSON", package: "swift-json"),
        .product(name: "Package Manager", package: "swift-package-manager"),
        .product(name: "Process", package: "swift-process"),
      ]
    ),
    .target(
      name: "Institute Application Repository",
      dependencies: [
        "Institute GitHub",
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Console", package: "swift-console"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "Kernel", package: "swift-kernel"),
        .product(name: "RFC 4648", package: "swift-rfc-4648"),
        .product(name: "RFC 3339", package: "swift-rfc-3339"),
        .product(name: "Time Primitive", package: "swift-time-primitives"),
        .product(
          name: "Byte Primitives Standard Library Integration",
          package: "swift-byte-primitives"
        ),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Repository Policy", package: "institute"),
        .product(name: "Byte Primitives", package: "swift-byte-primitives"),
        .product(name: "FIPS 180-4", package: "swift-fips-180-4"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "GitHub", package: "swift-github"),
        .product(name: "GitHub App", package: "swift-github"),
        .product(name: "JSON", package: "swift-json"),
        .product(name: "Package Manager", package: "swift-package-manager"),
        .product(name: "Process", package: "swift-process"),
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
      name: "Institute Application Workspace",
      dependencies: [
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Development", package: "institute"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "Process", package: "swift-process"),
      ]
    ),
    .target(
      name: "Institute Application Doctor",
      dependencies: [
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Doctor", package: "institute"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "Process", package: "swift-process"),
      ]
    ),
    .target(
      name: "Institute Application Inventory",
      dependencies: [
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Doctor", package: "institute"),
        .product(name: "Institute Inventory", package: "institute"),
        .product(name: "Institute Pages", package: "institute"),
        .product(name: "Console", package: "swift-console"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "Process", package: "swift-process"),
      ]
    ),
    .target(
      name: "Institute Application Dependency",
      dependencies: [
        "Institute GitHub",
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Dependency", package: "institute"),
        .product(name: "Institute Inventory", package: "institute"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "Git", package: "swift-git"),
        .product(name: "Process", package: "swift-process"),
      ]
    ),
    .target(
      name: "Institute Application Composition",
      dependencies: [
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Development", package: "institute"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
      ]
    ),
    .target(
      name: "Institute Application Context",
      dependencies: [
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Development", package: "institute"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "Process", package: "swift-process"),
      ]
    ),
    .target(
      name: "Institute Application Navigation",
      dependencies: [
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Development", package: "institute"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
      ]
    ),
    .target(
      name: "Institute Application Package",
      dependencies: [
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Build Coordinator", package: "institute"),
        .product(name: "Institute Lint", package: "institute"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "Process", package: "swift-process"),
      ]
    ),
    .target(
      name: "Institute Application Lint",
      dependencies: [
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Lint", package: "institute"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "Process", package: "swift-process"),
      ]
    ),
    .target(
      name: "Institute Application Coherence",
      dependencies: [
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Instruments", package: "institute"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "Process", package: "swift-process"),
      ]
    ),
    .target(
      name: "Institute Application Conversion",
      dependencies: [
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Conversion", package: "institute"),
        .product(name: "Byte Primitives", package: "swift-byte-primitives"),
        .product(name: "Console", package: "swift-console"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "JSON", package: "swift-json"),
      ]
    ),
    .target(
      name: "Institute Application GitHub",
      dependencies: [
        "Institute GitHub",
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Console", package: "swift-console"),
        .product(name: "GitHub App", package: "swift-github"),
        .product(name: "Paths", package: "swift-paths"),
      ]
    ),
    .target(
      name: "Institute Application Verification",
      dependencies: [
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Instruments", package: "institute"),
        .product(name: "Byte Primitives", package: "swift-byte-primitives"),
        .product(name: "Console", package: "swift-console"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "Git", package: "swift-git"),
        .product(name: "JSON", package: "swift-json"),
        .product(name: "Process", package: "swift-process"),
      ]
    ),
    .target(
      name: "Institute Application Certification",
      dependencies: [
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Instruments", package: "institute"),
        .product(name: "Institute Doctor", package: "institute"),
        .product(name: "Byte Primitives", package: "swift-byte-primitives"),
        .product(name: "Console", package: "swift-console"),
        .product(name: "Environment", package: "swift-environment"),
        .product(name: "File System", package: "swift-file-system"),
        .product(name: "Git", package: "swift-git"),
        .product(name: "JSON", package: "swift-json"),
        .product(name: "Package Manager", package: "swift-package-manager"),
        .product(name: "Process", package: "swift-process"),
      ]
    ),
    .target(
      name: "Institute Application",
      dependencies: [
        "Institute Application CI",
        "Institute Application Certification",
        "Institute Application Coherence",
        "Institute Application Composition",
        "Institute Application Context",
        "Institute Application Conversion",
        "Institute Application Dependency",
        "Institute Application Doctor",
        "Institute Application GitHub",
        "Institute Application Inventory",
        "Institute Application Lint",
        "Institute Application Navigation",
        "Institute Application Package",
        "Institute Application Verification",
        "Institute Application Workspace",
        "Institute Application Repository",
        "Institute Application Source",
        "Institute Architecture CLI",
        "Institute Architecture Model",
        "Institute GitHub",
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "Command Schema", package: "swift-arguments"),
        .product(name: "Institute CI Model", package: "institute"),
        .product(name: "Institute Conversion", package: "institute"),
        .product(name: "Institute Dependency", package: "institute"),
        .product(name: "Institute Development", package: "institute"),
        .product(name: "Institute Doctor", package: "institute"),
        .product(name: "Institute Instruments", package: "institute"),
        .product(name: "Institute Inventory", package: "institute"),
        .product(name: "Institute Lint", package: "institute"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Repository Policy", package: "institute"),
      ],
      path: "Sources/Institute Application"
    ),
    .executableTarget(
      name: "Institute Application CLI",
      dependencies: [
        "Institute Application",
        "Institute Application Workspace",
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Command", package: "swift-arguments"),
      ]
    ),
    .testTarget(
      name: "Institute Architecture Tests",
      dependencies: [
        "Institute Architecture Model",
        "Institute Architecture Facts",
        "Institute Architecture Graph",
        "Institute Architecture Index",
        "Institute Architecture Validation",
        "Institute Architecture Candidates",
        "Institute Architecture Migration",
        "Institute Architecture CLI",
        .product(name: "Institute Model", package: "institute"),
      ],
      path: "Tests/Institute Architecture Tests"
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
        "Institute Application",
        "Institute Application Certification",
        "Institute Application Coherence",
        "Institute Application Composition",
        "Institute Application Context",
        "Institute Application Conversion",
        "Institute Application Dependency",
        "Institute Application Doctor",
        "Institute Application GitHub",
        "Institute Application Inventory",
        "Institute Application Lint",
        "Institute Application Navigation",
        "Institute Application Package",
        "Institute Application Verification",
        "Institute Application Workspace",
        .product(name: "Institute Build Coordinator", package: "institute"),
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Instruments", package: "institute"),
        .product(name: "Command", package: "swift-arguments"),
        .product(name: "JSON", package: "swift-json"),
      ],
      path: "Tests/Institute Application Tests"
    ),
    .testTarget(
      name: "Institute Application CI Tests",
      dependencies: [
        "Institute Application CI",
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Institute Repository Policy", package: "institute"),
        .product(name: "Institute CI Canon", package: "institute"),
        .product(name: "Institute CI Validation", package: "institute"),
      ]
    ),
    .testTarget(
      name: "Institute Application Repository Tests",
      dependencies: [
        "Institute Application Repository",
        "Institute GitHub",
        .product(name: "Institute Model", package: "institute"),
        .product(name: "Byte Primitives", package: "swift-byte-primitives"),
        .product(
          name: "Byte Primitives Standard Library Integration",
          package: "swift-byte-primitives"
        ),
        .product(name: "JSON", package: "swift-json"),
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
