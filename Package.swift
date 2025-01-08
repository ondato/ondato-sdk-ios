// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OndatoSDK",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "OndatoSDK",
                 targets: [
                    "OndatoSDK", "FaceTecSDK"
                 ]),
        .library(name: "OndatoNFC",
                 targets: [
                    "OndatoNFC", "OpenSSL"
                 ]),
        .library(name: "OndatoScreenRecorder",
                 targets: [
                    "OndatoScreenRecorder"
                 ])
    ],
    targets: [
        .binaryTarget(name: "OndatoSDK",
                      path: "Binaries/OndatoSDK.xcframework"),
        .binaryTarget(name: "FaceTecSDK",
                      path: "Binaries/FaceTecSDK.xcframework"),
        .binaryTarget(name: "OndatoNFC",
                      path: "Binaries/OndatoNFC.xcframework"),
        .binaryTarget(name: "OpenSSL",
                      path: "Binaries/OpenSSL.xcframework"),
        .binaryTarget(name: "OndatoScreenRecorder",
                      path: "Binaries/OndatoScreenRecorder.xcframework")
    ]
)
