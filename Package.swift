// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WindowPin",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "WindowPin",
            path: "Sources/WindowPin",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon"),
                .linkedFramework("ScreenCaptureKit"),
            ]
        ),
    ]
)
