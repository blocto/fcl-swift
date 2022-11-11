// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FCL-SDK",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "FCL_SDK",
            targets: ["FCL-SDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/portto/flow-swift-sdk.git", .upToNextMajor(from: "0.4.2")),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0"),
        .package(url: "https://github.com/portto/blocto-ios-sdk.git", .upToNextMinor(from: "0.4.2")),
    ],
    targets: [
        .target(
            name: "FCL-SDK",
            dependencies: [
                "SwiftyJSON",
                .product(name: "FlowSDK", package: "flow-swift-sdk"),
                .product(name: "BloctoSDK", package: "blocto-ios-sdk"),
            ]
        ),
        .testTarget(
            name: "FCLTests",
            dependencies: ["FCL-SDK"]
        ),
    ]
)
