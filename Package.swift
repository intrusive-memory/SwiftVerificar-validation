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
        .package(url: "https://github.com/intrusive-memory/SwiftVerificar-validation-profiles.git", branch: "main"),
        .package(url: "https://github.com/intrusive-memory/SwiftVerificar-parser.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "SwiftVerificarValidation",
            dependencies: [
                .product(name: "SwiftVerificarValidationProfiles", package: "SwiftVerificar-validation-profiles"),
                .product(name: "SwiftVerificarParser", package: "SwiftVerificar-parser"),
            ]
        ),
        .testTarget(
            name: "SwiftVerificarValidationTests",
            dependencies: [
                "SwiftVerificarValidation",
                .product(name: "SwiftVerificarParser", package: "SwiftVerificar-parser"),
            ]
        ),
    ]
)
