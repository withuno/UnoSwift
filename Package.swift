// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "UnoSwift",
    platforms: [
        .iOS(SupportedPlatform.IOSVersion.v14),
        .macOS(SupportedPlatform.MacOSVersion.v11),
    ],
    products: [
        .library(
            name: "UnoSwift",
            targets: ["Uno"]),
    ],
    targets: [
        .target(
            name: "Uno",
            dependencies: ["C"],
            path: "Sources/Swift"),
        .target(
            name: "C",
            dependencies: ["UnoRust"],
            path: "Sources/C"),
        .binaryTarget(
            name: "UnoRust",
            path: "Libs/UnoRust.xcframework"),
        .testTarget(
            name: "Uno-Tests",
            dependencies: ["Uno"],
            path: "Tests/Swift"),
    ]
)
