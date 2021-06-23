// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cache",
    products: [
        .library(
            name: "Cache",
            targets: ["Cache"]
        ),
        .library(
            name: "PersistentCache",
            targets: ["PersistentCache"]),
        .library(
            name: "MemoryCache",
            targets: ["MemoryCache"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Cache",
            dependencies: [],
            path: "Sources/Cache"
        ),
        .target(
            name: "MemoryCache",
            dependencies: [
                "Cache"
            ],
            path: "Sources/MemoryCache"
        ),
        .target(
            name: "PersistentCache",
            dependencies: [
                "Cache",
                "MemoryCache"
            ],
            path: "Sources/PersistentCache"
        ),
        .testTarget(
            name: "CacheTests",
            dependencies: ["Cache", "MemoryCache", "PersistentCache"]),
    ]
)
