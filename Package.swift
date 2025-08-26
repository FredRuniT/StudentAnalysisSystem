// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StudentAnalysisSystem",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .executable(
            name: "StudentAnalysisSystem",
            targets: ["StudentAnalysisSystemMain"]
        ),
        .library(
            name: "AnalysisCore",
            targets: ["AnalysisCore"]
        ),
        .library(
            name: "StatisticalEngine",
            targets: ["StatisticalEngine"]
        ),
        .library(
            name: "PredictiveModeling",
            targets: ["PredictiveModeling"]
        ),
        .library(
            name: "ReportGeneration",
            targets: ["ReportGeneration"]
        ),
        .library(
            name: "IndividualLearningPlan",
            targets: ["IndividualLearningPlan"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
        .package(url: "https://github.com/CoreOffice/CoreXLSX", from: "0.14.0"),
        .package(url: "https://github.com/yaslab/CSV.swift", from: "2.5.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "AnalysisCore",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "CoreXLSX", package: "CoreXLSX"),
                .product(name: "CSV", package: "CSV.swift"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON")
            ]
        ),
        .target(
            name: "StatisticalEngine",
            dependencies: [
                "AnalysisCore",
                .product(name: "MLX", package: "mlx-swift")
            ]
        ),
        .target(
            name: "PredictiveModeling",
            dependencies: ["StatisticalEngine", "AnalysisCore"]
        ),
        .target(
            name: "ReportGeneration",
            dependencies: [
                "AnalysisCore",
                "PredictiveModeling",
                "IndividualLearningPlan"
            ]
        ),
        .target(
            name: "IndividualLearningPlan",
            dependencies: [
                "AnalysisCore",
                "StatisticalEngine",
                "PredictiveModeling"
            ]
        ),
        .testTarget(
            name: "AnalysisCoreTests",
            dependencies: ["AnalysisCore"]
        ),
        .executableTarget(
            name: "StudentAnalysisSystemMain",
            dependencies: [
                "AnalysisCore",
                "StatisticalEngine",
                "PredictiveModeling",
                "IndividualLearningPlan",
                "ReportGeneration"
            ]
        )
    ]
)