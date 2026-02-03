// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TypeBoi",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "TypeBoi", targets: ["TypeBoiApp"])
    ],
    targets: [
        .executableTarget(
            name: "TypeBoiApp",
            path: "Sources/TypeBoiApp"
        )
    ]
)
