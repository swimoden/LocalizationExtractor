// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocalizationExtractor",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "LocalizationExtractor",
            targets: ["LocalizationExtractor"]
        ),
    ],
    dependencies: [
        // No external dependencies yet
    ],
    targets: [
        .target(
            name: "LocalizationExtractor",
            path: "Sources/LocalizationExtractor"
        ),
        .testTarget(
            name: "LocalizationExtractorTests",
            dependencies: ["LocalizationExtractor"],
        ),
    ]
)
