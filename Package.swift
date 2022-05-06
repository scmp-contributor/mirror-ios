// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mirror-ios",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "mirror-ios",
            targets: ["mirror-ios"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "5.1.0")),
        .package(url: "https://github.com/RxSwiftCommunity/RxAlamofire.git", .upToNextMajor(from: "5.6.0")),
        .package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git", .upToNextMajor(from: "1.7.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "mirror-ios",
            dependencies: ["RxSwift",
                           .product(name: "RxCocoa", package: "RxSwift"),
                           "RxAlamofire",
                           "SwiftyBeaver"]),
        .testTarget(
            name: "mirror-iosTests",
            dependencies: ["mirror-ios",
                           .product(name: "RxTest", package: "RxSwift"),
                           .product(name: "RxBlocking", package: "RxSwift")]),
    ]
)
