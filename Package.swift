// swift-tools-version:5.4

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
            targets: ["UnoSwift"]),
    ],
    targets: [
        .target(
            name: "UnoSwift",
            dependencies: ["C"],
            path: "Sources/UnoSwift",
            sources: ["Uno.swift"]),
        .target(
            name: "C",
            dependencies: ["UnoStatic"],
            path: "Sources/C"),
        .binaryTarget(
            name: "UnoStatic",
            path: "Libs/UnoRust.xcframework"),
        .testTarget(
            name: "Uno-Tests",
            dependencies: ["UnoSwift"]),
    ]
)
