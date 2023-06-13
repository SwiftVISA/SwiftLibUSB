// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SwiftLibUSB",
    products: [
        .library(
            name: "SwiftLibUSB",
            targets: ["SwiftLibUSB"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftVISA/CoreSwiftVISA.git", .upToNextMinor(from: "0.1.0")),
    ],
    targets: [
        .systemLibrary(
            name: "CUsb",
            pkgConfig: "libusb-1.0",
            providers: [.brew(["libusb"])]),
        .target(
            name: "Usb",
            dependencies: ["CUsb"]),
        .target(
            name: "SwiftLibUSB",
            dependencies: ["CoreSwiftVISA", "Usb"]),
        .testTarget(
            name: "SwiftLibUSBTests",
            dependencies: ["SwiftLibUSB"])
    ]
)
