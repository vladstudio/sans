// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Font",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Font",
            path: "Sources/Font"
        )
    ]
)
