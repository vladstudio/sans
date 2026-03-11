// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Sans",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Sans",
            path: "Sources/Sans"
        )
    ]
)
