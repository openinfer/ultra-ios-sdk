// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UltraPackage",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "UltraPackage",
            targets: ["UltraPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/openinfer/ultra-verify-sdk-ios", branch: "main"),
        .package(url: "https://github.com/Alamofire/Alamofire", .upToNextMajor(from: "5.8.1")),
        .package(url: "https://github.com/relatedcode/ProgressHUD", from: "14.1.1"),
        .package(url: "https://github.com/alexiscreuzot/SwiftyGif", from: "5.4.5")
    ],
    targets: [
        .target(name: "UltraPackage",
                dependencies: [
                    .product(name: "CryptonetPackage", package: "ultra-verify-sdk-ios"),
                    "Alamofire",
                    "ProgressHUD",
                    "SwiftyGif"
                ]
        )
    ]
)
