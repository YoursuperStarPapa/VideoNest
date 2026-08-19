// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VideoNest",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "VideoNest", targets: ["VideoNest"])
    ],
    targets: [
        .target(
            name: "VideoNest",
            path: "VideoNest"
        )
    ]
)
