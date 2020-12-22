// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WPRemoteData",
    platforms: [
        .iOS(SupportedPlatform.IOSVersion.v11),
        ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        
        .library(
            name: "WPRemoteData",
            targets: ["WPRemoteData"]),
    ],
    dependencies: [
        .package(name: "Firebase", url: "https://github.com/firebase/firebase-ios-sdk.git", .branch("7.0-spm-beta")),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.8.0"),
        .package(name: "ReactiveSwift", url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "6.1.0"),
        .package(
            url: "https://github.com/BillPiotrowski/SPCommon3.git",
            from: "0.1.0"
        )
    ],
    targets: [
        .target(
            name: "WPRemoteData",
            dependencies: [
              // The product name you need. In this example, FirebaseAuth.
              //.product(name: "FirebaseCore", package: "Firebase"),
                //.product(name: "FirebaseAuth", package: "Firebase"),
              .product(name: "FirebaseFirestore", package: "Firebase"),
              .product(name: "FirebaseStorage", package: "Firebase"),
              .product(name: "FirebaseFunctions", package: "Firebase"),
                .product(name: "PromiseKit", package: "PromiseKit"),
                .product(name: "ReactiveSwift", package: "ReactiveSwift"),
                .product(name: "SPCommon3", package: "SPCommon3")
            ]
        ),
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
//        .target(
//            name: "WPRemoteData",
//            dependencies: []),
        .testTarget(
            name: "WPRemoteDataTests",
            dependencies: ["WPRemoteData"]),
    ]
)
