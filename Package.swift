// swift-tools-version:6.4
import PackageDescription

var dependencies: [Package.Dependency] = [
    // https://github.com/CreateAPI/URLQueryEncoder
    .package(url: "https://github.com/CreateAPI/URLQueryEncoder", from: "0.2.1"),

    // https://github.com/apple/swift-crypto
    .package(url: "https://github.com/apple/swift-crypto", from: "5.0.3"),

    // https://github.com/apple/swift-argument-parser
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),

    // https://github.com/weichsel/ZIPFoundation
    .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.20"),

    // https://github.com/apple/swift-collections
    .package(url: "https://github.com/apple/swift-collections", from: "1.7.5")
]

var targetDependencies: [Target.Dependency] = [
    .product(name: "URLQueryEncoder", package: "URLQueryEncoder"),
    .product(name: "Crypto", package: "swift-crypto")
]

#if os(Linux)
dependencies.append(.package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.14.0"))
targetDependencies.append(.product(name: "OpenCombine", package: "OpenCombine"))
#endif

let package = Package(
    name: "ASC",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "ASC", targets: ["ASC"])
    ],
    dependencies: dependencies,
    targets: [
        .testTarget(
            name: "ASC-Tests",
            dependencies: [
                "ASC",
                .target(name: "OpenAPIGeneratorCore", condition: .when(platforms: [.macOS]))
            ],
            path: "Tests"
        ),
        .target(
            name: "ASC",
            dependencies: targetDependencies,
            path: "Sources",
            exclude: [
                "OpenAPI/app_store_connect_api.json",
                "OpenAPI/create-api.yml"
            ]
        ),
        .target(
            name: "OpenAPIGeneratorCore",
            dependencies: [
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                .product(name: "OrderedCollections", package: "swift-collections")
            ],
            path: "Tools/OpenAPIGeneratorCore"
        ),
        .executableTarget(
            name: "OpenAPIGenerator",
            dependencies: [
                "OpenAPIGeneratorCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Tools/OpenAPIGenerator"
        ),
        .binaryTarget(
            name: "create-api", // Find the URL and checksum at https://github.com/createapi/createapi/releases/latest
            url: "https://github.com/CreateAPI/CreateAPI/releases/download/0.2.0/create-api.artifactbundle.zip",
            checksum: "6f8a3ce099f07eb2655ccaf6f66d8c9a09b74bb2307781c4adec36609ddac009"
        ),
        .plugin(
            name: "CreateAPI",
            capability: .command(
                intent: .custom(
                    verb: "generate-open-api",
                    description: "Generates the OpenAPI entities and paths using CreateAPI"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "To output the generated source code")
                ]
            ),
            dependencies: [
                .target(name: "create-api")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
