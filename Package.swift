// swift-tools-version: 5.9
import Foundation
import PackageDescription

/// Embed a minimal Info.plist so `Bundle.main.bundleIdentifier` exists (fixes window tab indexing, handoff, etc.).
let infoPlistPath = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("Info.plist")
    .path

let package = Package(
    name: "WorkPane",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "WorkPane", targets: ["WorkPane"]),
    ],
    targets: [
        .executableTarget(
            name: "WorkPane",
            path: "Sources/WorkPane",
            resources: [
                .copy("Resources/Assets.car"),
                .copy("Resources/en.lproj"),
                .copy("Resources/fr.lproj"),
                .copy("Resources/de.lproj"),
                .copy("Resources/es.lproj"),
                .copy("Resources/it.lproj"),
            ],
            linkerSettings: [
                .unsafeFlags(
                    [
                        "-Xlinker", "-sectcreate",
                        "-Xlinker", "__TEXT",
                        "-Xlinker", "__info_plist",
                        "-Xlinker", infoPlistPath,
                    ],
                    .when(platforms: [.macOS])
                ),
            ]
        ),
    ]
)
