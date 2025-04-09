// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RefreshTokenAuthMiddleware",
    defaultLocalization: "en",
    platforms: [.macOS(.v12), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .visionOS(.v1)],
    products: [
        .library(
            name: "RefreshTokenAuthMiddleware",
            targets: ["RefreshTokenAuthMiddleware"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-http-types", from: "1.4.0"),
    ],
    targets: [
        .target(
            name: "RefreshTokenAuthMiddleware",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
                .product(name: "HTTPTypes", package: "swift-http-types")
            ]),
//        .testTarget(
//            name: "RefreshTokenAuthMiddlewareTests",
//            dependencies: ["RefreshTokenAuthMiddleware"]
//        ),
    ]
)
