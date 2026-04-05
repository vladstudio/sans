// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sans",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Sans",
            path: "Sources/Sans"
        )
    ]
)
