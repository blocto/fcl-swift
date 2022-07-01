// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FCL",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FCL",
            targets: ["FCL"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/portto/flow-swift-sdk.git", .upToNextMajor(from: "0.1.0")),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "FCL",
            dependencies: [
                "SwiftyJSON",
                .product(name: "FlowSDK", package: "flow-swift-sdk")
            ]
        ),
        .testTarget(
            name: "FCLTests",
            dependencies: ["FCL"]
        )
    ]
)
