// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "ConcurrencyCollection",
  platforms: [
    .iOS(.v14),
    .macCatalyst(.v15)
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
                .productItem(name: "Collections",package: "swift-collections"),
            ],
            path: "ConcurrencyCollection"
        ),
  ]
)
