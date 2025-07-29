// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MGUtils",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MGUtils",
            targets: ["MGUtils"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MGUtils",
            linkerSettings: [
                .linkedFramework("UIKit", .when(platforms: [.iOS])) // 关键：显式链接 UIKit[3,5](@ref)
            ]
        ),
        
        .testTarget(
            name: "MGUtilsTests",
            dependencies: ["MGUtils"]
        ),
    ]
)
