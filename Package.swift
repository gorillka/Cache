// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CacheKit",
    products: [
        .library(
            name: "CacheKit",
            targets: ["CacheKit"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CacheKit",
            dependencies: []
            ),
        .testTarget(
            name: "CacheKitTests",
            dependencies: ["CacheKit"]),
    ]
)
