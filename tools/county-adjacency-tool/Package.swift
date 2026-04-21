// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CountyAdjacencyTool",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "county-adjacency-tool", targets: ["CountyAdjacencyTool"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "CountyAdjacencyTool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "CountyAdjacencyToolTests",
            dependencies: ["CountyAdjacencyTool"]
        )
    ]
)
