// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Mivio",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MivioCore",
            targets: ["MivioCore"]
        ),
        .library(
            name: "MivioUI",
            targets: ["MivioUI"]
        )
    ],
    dependencies: [
        // Modern and efficient image loading for SwiftUI
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.11.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MivioCore",
            dependencies: []
        ),
        .target(
            name: "MivioUI",
            dependencies: [
                "MivioCore",
                .product(name: "Kingfisher", package: "Kingfisher")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MivioCoreTests",
            dependencies: ["MivioCore"]
        )
    ]
)
