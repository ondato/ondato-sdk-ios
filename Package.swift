// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OndatoSDK",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(name: "OndatoSDK",
                 targets: [
                    "OndatoSDKDependencies"
                 ]),
        .library(name: "OndatoNFC",
                 targets: [
                    "OndatoNFC", "OpenSSL"
                 ]),
        .library(name: "OndatoScreenRecorder",
                 targets: [
                    "OndatoScreenRecorder"
                 ]),
        .library(name: "OndatoAutocapture",
                 targets: [
                    "OndatoAutocapture"
                 ]),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", .upToNextMajor(from: "4.5.2")),
    ],
    targets: [
        .target(name: "OndatoSDKDependencies",
                dependencies: [
                    "OndatoSDK",
                    "FaceTecSDK",
                    .product(name: "Lottie", package: "lottie-spm"),
                ],
                path: "Sources/OndatoSDKDependencies"),
        .binaryTarget(name: "OndatoSDK",
                      path: "Binaries/OndatoSDK.xcframework"),
        .binaryTarget(name: "FaceTecSDK",
                      path: "Binaries/FaceTecSDK.xcframework"),
        .binaryTarget(name: "OndatoNFC",
                      path: "Binaries/OndatoNFC.xcframework"),
        .binaryTarget(name: "OpenSSL",
                      path: "Binaries/OpenSSL.xcframework"),
        .binaryTarget(name: "OndatoScreenRecorder",
                      path: "Binaries/OndatoScreenRecorder.xcframework"),
        .binaryTarget(name: "OndatoAutocapture",
                      path: "Binaries/OndatoAutocapture.xcframework")
    ]
)
