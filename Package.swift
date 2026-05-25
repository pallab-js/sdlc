// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SDLCApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SDLCApp", targets: ["SDLCApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.1"),
        .package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.0.2"),
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.10.0")
    ],
    targets: [
        .executableTarget(
            name: "SDLCApp",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui")
            ],
            path: "Sources/SDLCApp"
        ),
        .testTarget(
            name: "SDLCTests",
            dependencies: [
                "SDLCApp",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/SDLCTests"
        )
    ]
)
