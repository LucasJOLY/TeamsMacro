// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TeamsMacro",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "TeamsMacro", targets: ["TeamsMacro"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "TeamsMacro",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ]
        )
    ]
)
