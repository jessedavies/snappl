// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "WindowSnapper",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "WindowSnapper", path: "Sources/WindowSnapper")
    ]
)
