// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TmuxBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TmuxBar", targets: ["TmuxBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "TmuxBar",
            dependencies: ["HotKey"],
            path: "Sources/TmuxBar"
        )
    ]
)
