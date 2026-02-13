// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "SuhyNetWorker",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13),
        .tvOS(.v12),
        .watchOS(.v5)
    ],
    products: [
        .library(
            name: "SuhyNetWorker",
            targets: ["SuhyNetWorker"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/Alamofire/Alamofire.git",
            from: "5.6.4"
        ),
        .package(
            url: "https://github.com/hyperoslo/Cache.git",
            from: "6.0.0"
        )
    ],
    targets: [
        .target(
            name: "SuhyNetWorker",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "Cache", package: "Cache")
            ],
            path: "SuhyNetWorker/SuhyNetWorker",
            exclude: []
        ),
        .testTarget(
            name: "SuhyNetWorkerTests",
            dependencies: ["SuhyNetWorker"],
            path: "Tests",
            exclude: []
        )
    ]
)
