// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "GameMusicKit",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "GameMusicKit",
            targets: ["GameMusicKit"]
        ),
        .executable(
            name: "GameMusicKitDemo",
            targets: ["GameMusicKitDemo"]
        ),
    ],
    targets: [
        .target(
            name: "GameMusicKit"
        ),
        .executableTarget(
            name: "GameMusicKitDemo",
            dependencies: ["GameMusicKit"]
        ),
        .testTarget(
            name: "GameMusicKitTests",
            dependencies: ["GameMusicKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
