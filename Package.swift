// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

private let concurrency = Target.Dependency.product(name: "ConcurrencyExtras", package: "swift-concurrency-extras")

let package = Package(
  name: "SWLogger",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "SWLogger",
      targets: ["SWLogger"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.2.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(
      name: "SWLogger",
      dependencies: [
        concurrency
      ]
    ),
    .testTarget(
      name: "SWLoggerTests",
      dependencies: ["SWLogger"]),
  ]
)
