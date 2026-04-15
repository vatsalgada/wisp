// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Wisp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Wisp", targets: ["Wisp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Wisp",
            dependencies: [
                "whisper"
            ],
            path: "Sources"
        ),
        .binaryTarget(
            name: "whisper",
            url: "https://github.com/ggml-org/whisper.cpp/releases/download/v1.8.1/whisper-v1.8.1-xcframework.zip",
            checksum: "fc02a7efe6ede7a73c032ee2e67027766e49e3ff8cb35aa8651519ec1ab97cb7"
        ),
    ]
)
