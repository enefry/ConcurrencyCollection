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
    .package(url: "https://github.com/apple/swift-collections.git", from:"1.6.0"),
  ],
  targets: [
    .target(
            name: "ConcurrencyCollection",
            dependencies: [
                .product(name: "Collections",package: "swift-collections"),
                .product(name: "DequeModule", package: "swift-collections"),
                .product(name: "OrderedCollections", package: "swift-collections"),
            ],
            path: "ConcurrencyCollection"
        ),
  ]
)
