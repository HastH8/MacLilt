// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacEase",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MacEase", targets: ["MacEase"])
    ],
    targets: [
        .executableTarget(
            name: "MacEase",
            path: "MacEase",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "MacEaseTests",
            dependencies: ["MacEase"],
            path: "Tests/MacEaseTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
