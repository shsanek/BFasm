// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BFASM",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "BFASM",
            targets: ["BFASM"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "BFASM"),
        .executableTarget(
            name: "AsmBuilder"),
        .testTarget(
            name: "BFASMTests",
            dependencies: ["BFASM"]),
    ]
)
