// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Template",
    products: [
        .library(
            name: "Template",
            targets: ["Template"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Template",
            dependencies: []),
        .testTarget(
            name: "TemplateTests",
            dependencies: ["Template"]),
    ]
)
