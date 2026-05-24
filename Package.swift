// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReverseMouseScroll",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "ReverseMouseScroll",
            path: "ReverseMouseScroll",
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("CoreGraphics")
            ]
        )
    ]
)
