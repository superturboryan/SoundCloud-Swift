// swift-tools-version: 5.11
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SoundCloud",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .watchOS(.v9), .macOS(.v14)],
    products: [
        .library(
            name: "SoundCloud",
            type: .static,
            targets: ["SoundCloud"]),
    ],
    dependencies: [
        .package(url: "https://github.com/evgenyneu/keychain-swift", from: "20.0.0"),
        .package(url: "https://github.com/superturboryan/Consolable/" , exact: "1.0.0")
    ],
    targets: [
        .target(
            name: "SoundCloud",
            dependencies: [
                .product(name: "KeychainSwift", package: "keychain-swift"),
                .product(name: "Consolable", package: "Consolable"),
            ]
        ),
        .testTarget(
            name: "SoundCloudTests",
            dependencies: ["SoundCloud"]),
    ]
)
