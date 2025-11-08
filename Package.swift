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

    targets: [
        .target(
            name: "Crossword",
            dependencies: []),

        .executableTarget(
            name: "CrosswordMaker",
            dependencies: ["Crossword"]
        ),

        .testTarget(
            name: "CrosswordTests",
            dependencies: ["Crossword"]),
    ]
)
