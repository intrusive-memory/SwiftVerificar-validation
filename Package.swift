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
        .package(path: "../SwiftVerificar-validation-profiles")
        // Parser dependency temporarily disabled - using type stubs in ParserTypes.swift
        // .package(path: "../SwiftVerificar-parser")
    ],
    targets: [
        .target(
            name: "SwiftVerificarValidation",
            dependencies: [
                .product(name: "SwiftVerificarValidationProfiles", package: "SwiftVerificar-validation-profiles")
                // Parser dependency temporarily disabled - using type stubs in ParserTypes.swift
                // .product(name: "SwiftVerificarParser", package: "SwiftVerificar-parser")
            ]
        ),
        .testTarget(
            name: "SwiftVerificarValidationTests",
            dependencies: ["SwiftVerificarValidation"]
        ),
    ]
)
