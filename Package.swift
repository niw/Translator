// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Translator",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Translator",
            targets: [
                "TranslatorSupport"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ggerganov/llama.cpp.git", branch: "b3761"),
    ],
    targets: [
        .target(
            name: "TranslatorSupport",
            dependencies: [
                .target(name: "LlamaModel")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "LlamaModel",
            dependencies: [
                .product(name: "llama", package: "llama.cpp")
            ]
        )
    ]
)
