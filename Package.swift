// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacSensors",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "MacSensorsCore", path: "Sources/MacSensorsCore"),
        .executableTarget(name: "MacSensors", dependencies: ["MacSensorsCore"], path: "Sources/MacSensors"),
        .executableTarget(name: "MacSensorsTests", dependencies: ["MacSensorsCore"], path: "Sources/MacSensorsTests"),
    ]
)
