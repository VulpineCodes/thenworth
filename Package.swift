// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThenworthCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "ThenworthCore",
            targets: ["ThenworthCore"]
        ),
    ],
    targets: [
        .target(
            name: "ThenworthCore",
            path: "Sources/ThenworthCore"
        ),
        .testTarget(
            name: "ThenworthCoreTests",
            dependencies: ["ThenworthCore"],
            path: "Tests/ThenworthCoreTests"
        ),
    ]
)
