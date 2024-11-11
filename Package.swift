// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CryptonetPackage",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "CryptonetPackage",
            targets: ["CryptonetPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", .upToNextMajor(from: "5.8.1")),
        .package(url: "https://github.com/relatedcode/ProgressHUD", from: "14.1.1"),
        .package(url: "https://github.com/alexiscreuzot/SwiftyGif", from: "5.4.5")
    ],
    targets: [
        .target(name: "CryptonetPackage",
                dependencies: [
                    .target(
                        name: "privid_fhe_uber"
                    ),
                    "Alamofire",
                    "ProgressHUD",
                    "SwiftyGif"
                ]
        ),
        .binaryTarget(name: "privid_fhe_uber", path: "./privid_fhe_uber.xcframework")
    ]
)
