// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LRExportHEIC",
  platforms: [.macOS(.v12)],
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
