// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Napkin",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Napkin", targets: ["Napkin"])
    ],
    targets: [
        .executableTarget(name: "Napkin")
    ]
)
