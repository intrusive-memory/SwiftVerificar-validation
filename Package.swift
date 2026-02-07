// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftVerificarValidation",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SwiftVerificarValidation",
            targets: ["SwiftVerificarValidation"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/intrusive-memory/SwiftVerificar-validation-profiles.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "SwiftVerificarValidation",
            dependencies: [
                .product(name: "SwiftVerificarValidationProfiles", package: "SwiftVerificar-validation-profiles"),
            ]
        ),
        .testTarget(
            name: "SwiftVerificarValidationTests",
            dependencies: ["SwiftVerificarValidation"]
        ),
    ]
)
