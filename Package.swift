// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LRExportHEIC",
  platforms: [.macOS(.v15)],
  dependencies: [
    .package(url: "https://github.com/vapor/console-kit.git", from: "4.2.7")
  ],
  targets: [
    .executableTarget(
      name: "LRExportHEIC",
      dependencies: [
        .product(name: "ConsoleKit", package: "console-kit")
      ]
    ),
    .testTarget(
      name: "LRExportHEICTests",
      dependencies: ["LRExportHEIC"]),
  ]
)
