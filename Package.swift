// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-git",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "Git", targets: ["Git Foundation"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-git-standard.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-process.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Git Foundation",
            dependencies: [
                .product(name: "Git Standard", package: "swift-git-standard"),
                .product(name: "Process", package: "swift-process"),
            ],
            path: "Sources/Git"
        ),
        .testTarget(
            name: "Git Tests",
            dependencies: ["Git Foundation"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableExperimentalFeature("LifetimeDependence"),
            .enableExperimentalFeature("Lifetimes"),
            .enableExperimentalFeature("SuppressedAssociatedTypes"),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("LifetimeDependence"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        ]
}
