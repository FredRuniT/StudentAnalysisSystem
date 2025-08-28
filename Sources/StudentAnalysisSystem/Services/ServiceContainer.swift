import AnalysisCore
import Foundation
import IndividualLearningPlan
import PredictiveModeling
import StatisticalEngine
//
//  ServiceContainer.swift
//  StudentAnalysisSystem
//
//  Dependency injection container for app services
//


/// Central service container for dependency injection
@MainActor
/// ServiceContainer represents...
public class ServiceContainer: ObservableObject {
    /// shared property
    public static let shared = ServiceContainer()
    
    // Core Services
    private(set) lazy var standardsRepository = StandardsRepository(
        standardsDirectory: URL(fileURLWithPath: ConfigurationService.shared.standardsPath)
    )
    private(set) lazy var correlationAnalyzer = CorrelationAnalyzer()
    private(set) lazy var blueprintManager = BlueprintManager.shared
    
    // Prediction Services
    private(set) lazy var correlationEngine = ComponentCorrelationEngine()
    private(set) lazy var warningSystem = EarlyWarningSystem(
        correlationAnalyzer: correlationAnalyzer,
        configuration: SystemConfiguration.default
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
    /// isInitialized property
    @Published public var isInitialized = false
    /// initializationError property
    @Published public var initializationError: Error?
    /// correlationModel property
    @Published public var correlationModel: ValidatedCorrelationModel?
    /// students property
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
        /// outputURL property
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
            /// data property
            let data = try Data(contentsOf: outputURL)
            /// decoder property
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
        /// sourceComponent property
        let sourceComponent = ComponentIdentifier(
            grade: 4,
            subject: "MATH",
            component: "D1OP",
            testProvider: .nwea
        )
        
        /// targetComponent1 property
        let targetComponent1 = ComponentIdentifier(
            grade: 5,
            subject: "MATH",
            component: "D3OP", 
            testProvider: .nwea
        )
        
        /// targetComponent2 property
        let targetComponent2 = ComponentIdentifier(
            grade: 5,
            subject: "MATH",
            component: "D4OP",
            testProvider: .nwea
        )
        
        /// sampleCorrelations property
        let sampleCorrelations = [
            ComponentCorrelationMap(
                sourceComponent: sourceComponent,
                correlations: [
                    ComponentCorrelation(
                        target: targetComponent1,
                        correlation: 0.92,
                        confidence: 0.9999,
                        sampleSize: 1000
                    ),
                    ComponentCorrelation(
                        target: targetComponent2,
                        correlation: 0.85,
                        confidence: 0.999,
                        sampleSize: 1000
                    )
                ]
            )
        ]
        
        /// validationResults property
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
                studentInfo: StudentAssessmentData.StudentInfo(
                    msis: "MS123456",
                    name: "Sarah Johnson",
                    school: "Lincoln Elementary",
                    district: "Sample District"
                ),
                year: 2024,
                grade: 4,
                assessments: [
                    StudentAssessmentData.SubjectAssessment(
                        subject: "MATH",
                        testProvider: .nwea,
                        componentScores: [
                            "D1OP": 65.0,
                            "D2OP": 78.0,
                            "D3OP": 82.0,
                            "D4OP": 71.0
                        ],
                        overallScore: 725.0,
                        proficiencyLevel: "Proficient"
                    )
                ]
            ),
            StudentAssessmentData(
                studentInfo: StudentAssessmentData.StudentInfo(
                    msis: "MS789012",
                    name: "Michael Davis",
                    school: "Roosevelt Elementary", 
                    district: "Sample District"
                ),
                year: 2024,
                grade: 3,
                assessments: [
                    StudentAssessmentData.SubjectAssessment(
                        subject: "ELA",
                        testProvider: .questar,
                        componentScores: [
                            "RC1": 62.0,
                            "RC2": 71.0,
                            "LA1": 69.0,
                            "LA2": 65.0
                        ],
                        overallScore: 680.0,
                        proficiencyLevel: "Basic"
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
        /// data property
        let data = try Data(contentsOf: url)
        /// decoder property
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ValidatedCorrelationModel.self, from: data)
    }
}