// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Transcribe",
  platforms: [.macOS(.v27)],
  products: [
    .executable(name: "transcribe", targets: ["Transcribe"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),
    .package(url: "https://github.com/apple/swift-log", from: "1.16.1"),
  ],
  targets: [
    .executableTarget(
      name: "Transcribe",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Logging", package: "swift-log"),
      ],
      swiftSettings: [.enableUpcomingFeature("ApproachableConcurrency")],
    )
  ],
)
