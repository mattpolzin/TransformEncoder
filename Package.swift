// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TransformEncoder",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "TransformEncoder",
            targets: ["TransformEncoder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mattpolzin/OrderedDictionary.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/mattpolzin/Poly.git", .upToNextMajor(from: "2.3.1")),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "2.0.0")) // only for tests
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "TransformEncoder",
            dependencies: ["Poly", "OrderedDictionary"]),
        .testTarget(
            name: "TransformEncoderTests",
            dependencies: ["TransformEncoder", "Yams"]),
    ]
)
