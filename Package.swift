// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Crossword",
    platforms: [
        .macOS(.v12)
    ],

    products: [
        .executable(
            name: "CrosswordMaker",
            targets: ["CrosswordMaker"]
        )
    ],

    dependencies: [
        .package(
            url: "https://github.com/apple/swift-collections.git",
            .upToNextMajor(from: "1.3.0")
        ),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
    ],

    targets: [
        .target(
            name: "Crossword",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms"),
            ]),

        .executableTarget(
            name: "CrosswordMaker",
            dependencies: [
                "Crossword",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),

        .testTarget(
            name: "CrosswordTests",
            dependencies: ["Crossword"]),
    ]
)
