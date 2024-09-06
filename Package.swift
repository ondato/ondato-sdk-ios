// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OndatoSDK",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "OndatoSDK",
            targets: ["OndatoSDK", "FaceTecSDK"]),
    ],
    targets: [
        .binaryTarget(name: "OndatoSDK",
                      path: "./OndatoSDK.xcframework"),
        .binaryTarget(name: "FaceTecSDK",
                      path: "./FaceTecSDK.xcframework")
    ]
)
