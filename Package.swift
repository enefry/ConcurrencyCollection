// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "ConcurrencyCollection",
  platforms: [
    .iOS(.v13),
    .macOS(.v11),
    .tvOS(.v13),
    .watchOS(.v7),
  ],
  products: [
    .library(name: "ConcurrencyCollection", targets: ["ConcurrencyCollection"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections.git", from:"1.0.4"),
  ],
  targets: [
    .target(
            name: "ConcurrencyCollection",
            dependencies: [
                .product(name: "Collections",package: "swift-collections"),
            ],
            path: "ConcurrencyCollection"
        ),
  ]
)
