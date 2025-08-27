//
//  ServiceContainer.swift
//  StudentAnalysisSystem
//
//  Dependency injection container for app services
//

import Foundation
import AnalysisCore
import StatisticalEngine
import PredictiveModeling
import IndividualLearningPlan

/// Central service container for dependency injection
@MainActor
public class ServiceContainer: ObservableObject {
    public static let shared = ServiceContainer()
    
    // Core Services
    private(set) lazy var standardsRepository = StandardsRepository()
    private(set) lazy var correlationAnalyzer = CorrelationAnalyzer()
    private(set) lazy var blueprintManager = BlueprintManager.shared
    
    // Prediction Services
    private(set) lazy var correlationEngine = ComponentCorrelationEngine()
    private(set) lazy var warningSystem = EarlyWarningSystem(
        correlationAnalyzer: correlationAnalyzer,
        thresholds: EarlyWarningSystem.defaultThresholds()
    )
    
    // ILP Services
    private(set) lazy var ilpGenerator = ILPGenerator(
        standardsRepository: standardsRepository,
        correlationEngine: correlationAnalyzer,
        warningSystem: warningSystem,
        configuration: SystemConfiguration.default,
        blueprintManager: blueprintManager,
        componentCorrelationEngine: correlationEngine
    )
    
    // Data Loading Services
    private(set) lazy var dataLoader = DataLoader()
    
    // State Management
    @Published public var isInitialized = false
    @Published public var initializationError: Error?
    @Published public var correlationModel: ValidatedCorrelationModel?
    @Published public var students: [StudentAssessmentData] = []
    
    private init() {}
    
    /// Initialize all services and load data
    public func initializeServices() async {
        do {
            // Load blueprints and standards
            try blueprintManager.loadAllBlueprints()
            try blueprintManager.loadAllStandards()
            
            // Load correlation model if available
            await loadCorrelationModel()
            
            // Load student data
            await loadStudentData()
            
            isInitialized = true
            initializationError = nil
        } catch {
            initializationError = error
            isInitialized = false
            print("Failed to initialize services: \(error)")
        }
    }
    
    /// Load correlation model from output directory
    private func loadCorrelationModel() async {
        let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Output")
            .appendingPathComponent("correlation_model.json")
        
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            print("Correlation model not found at \(outputURL.path)")
            // Use mock model for development
            correlationModel = createMockCorrelationModel()
            return
        }
        
        do {
            let data = try Data(contentsOf: outputURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            correlationModel = try decoder.decode(ValidatedCorrelationModel.self, from: data)
            print("Loaded correlation model with \(correlationModel?.correlations.count ?? 0) correlations")
        } catch {
            print("Failed to load correlation model: \(error)")
            // Use mock model as fallback
            correlationModel = createMockCorrelationModel()
        }
    }
    
    /// Load student assessment data
    private func loadStudentData() async {
        // For now, use mock data
        // TODO: Integrate with NWEAParser and QUESTARParser
        students = createMockStudents()
    }
    
    /// Create mock correlation model for development
    private func createMockCorrelationModel() -> ValidatedCorrelationModel {
        // Create sample correlations for demo
        let sampleCorrelations = [
            ComponentCorrelationMap(
                sourceGrade: 4,
                sourceComponent: "MATH_D1OP",
                correlations: [
                    ComponentCorrelation(
                        targetGrade: 5,
                        targetComponent: "MATH_D3OP",
                        correlation: 0.92,
                        pValue: 0.0001,
                        sampleSize: 1000,
                        confidence: 0.9999,
                        significance: .veryHighlySignificant
                    ),
                    ComponentCorrelation(
                        targetGrade: 5,
                        targetComponent: "MATH_D4OP",
                        correlation: 0.85,
                        pValue: 0.001,
                        sampleSize: 1000,
                        confidence: 0.999,
                        significance: .highlySignificant
                    )
                ]
            )
        ]
        
        let validationResults = ValidationResults(
            accuracy: 0.92,
            precision: 0.89,
            recall: 0.91,
            f1Score: 0.90,
            confusionMatrix: ValidationResults.ConfusionMatrix(
                truePositives: 180,
                trueNegatives: 170,
                falsePositives: 20,
                falseNegatives: 30
            )
        )
        
        return ValidatedCorrelationModel(
            correlations: sampleCorrelations,
            validationResults: validationResults,
            confidenceThreshold: 0.7,
            trainedDate: Date()
        )
    }
    
    /// Create mock students for development
    private func createMockStudents() -> [StudentAssessmentData] {
        return [
            StudentAssessmentData(
                msis: "MS123456",
                firstName: "Sarah",
                lastName: "Johnson",
                grade: 4,
                schoolYear: "2024-2025",
                assessments: [
                    Assessment(
                        testName: "MAAP",
                        date: Date(),
                        subject: "MATH",
                        overallScore: 725,
                        overallScoreConverted: 75,
                        proficiencyLevel: .proficient,
                        components: [
                            AssessmentComponent(identifier: "D1OP", score: 65, subScore: nil),
                            AssessmentComponent(identifier: "D2OP", score: 78, subScore: nil),
                            AssessmentComponent(identifier: "D3OP", score: 82, subScore: nil),
                            AssessmentComponent(identifier: "D4OP", score: 71, subScore: nil)
                        ]
                    )
                ]
            ),
            StudentAssessmentData(
                msis: "MS789012",
                firstName: "Michael",
                lastName: "Davis",
                grade: 3,
                schoolYear: "2024-2025",
                assessments: [
                    Assessment(
                        testName: "MAAP",
                        date: Date(),
                        subject: "ELA",
                        overallScore: 680,
                        overallScoreConverted: 68,
                        proficiencyLevel: .basic,
                        components: [
                            AssessmentComponent(identifier: "RC1", score: 62, subScore: nil),
                            AssessmentComponent(identifier: "RC2", score: 71, subScore: nil),
                            AssessmentComponent(identifier: "LA1", score: 69, subScore: nil),
                            AssessmentComponent(identifier: "LA2", score: 65, subScore: nil)
                        ]
                    )
                ]
            )
        ]
    }
}

/// Data loader service
public class DataLoader {
    /// Load students from CSV files
    public func loadStudentsFromCSV(directory: URL) async throws -> [StudentAssessmentData] {
        // TODO: Implement CSV loading with NWEAParser and QUESTARParser
        return []
    }
    
    /// Load correlation model from JSON
    public func loadCorrelationModel(from url: URL) async throws -> ValidatedCorrelationModel? {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ValidatedCorrelationModel.self, from: data)
    }
}