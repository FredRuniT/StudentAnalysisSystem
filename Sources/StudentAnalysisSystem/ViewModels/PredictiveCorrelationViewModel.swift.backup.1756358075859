import AnalysisCore
import IndividualLearningPlan
import PredictiveModeling
import StatisticalEngine
import SwiftUI

@MainActor
class PredictiveCorrelationViewModel: ObservableObject {
    @Published var topCorrelationsByCategory: [String: [CorrelationPrediction]] = [:]
    @Published var selectedStudent: StudentAssessmentData?
    @Published var studentPredictions: [FuturePrediction] = []
    @Published var isGeneratingILP = false
    @Published var isLoadingCorrelations = false
    @Published var selectedCorrelation: CorrelationPrediction?
    @Published var generatedILP: IndividualLearningPlan?
    @Published var searchText = ""
    @Published var minimumCorrelationStrength: Double = 0.7
    
    private var correlationEngine: ComponentCorrelationEngine?
    private var ilpGenerator: ILPGenerator?
    private var correlationModel: ValidatedCorrelationModel?
    
    // Reporting categories for grouping
    let reportingCategories = [
        ReportingCategory(id: "OA", name: "Operations & Algebraic Thinking", components: ["D1", "D2"]),
        ReportingCategory(id: "NBT", name: "Number & Operations Base Ten", components: ["D3", "D4"]),
        ReportingCategory(id: "NF", name: "Fractions", components: ["D5", "D6"]),
        ReportingCategory(id: "MD", name: "Measurement & Data", components: ["D7", "D8"]),
        ReportingCategory(id: "G", name: "Geometry", components: ["D9", "D0"]),
        ReportingCategory(id: "RC", name: "Reading Comprehension", components: ["RC"]),
        ReportingCategory(id: "LA", name: "Language Arts", components: ["LA"])
    ]
    
    init() {
        setupServices()
    }
    
    private func setupServices() {
        Task {
            // Use ServiceContainer for proper dependency injection
            let serviceContainer = ServiceContainer.shared
            await serviceContainer.initializeServices()
            
            // Get services from container
            correlationEngine = serviceContainer.correlationEngine
            ilpGenerator = serviceContainer.ilpGenerator
            
            // Load correlation model if it exists
            await loadCorrelationModel()
        }
    }
    
    private func loadCorrelationModel() async {
        do {
            let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Output")
                .appendingPathComponent("correlation_model.json")
            
            if FileManager.default.fileExists(atPath: outputURL.path) {
                let data = try Data(contentsOf: outputURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                correlationModel = try decoder.decode(ValidatedCorrelationModel.self, from: data)
                await loadTopCorrelations()
            }
        } catch {
            print("Error loading correlation model: \(error)")
        }
    }
    
    func loadTopCorrelations() async {
        guard let model = correlationModel else { return }
        
        await MainActor.run {
            isLoadingCorrelations = true
        }
        
        var categorizedCorrelations: [String: [CorrelationPrediction]] = [:]
        
        for category in reportingCategories {
            var categoryPredictions: [CorrelationPrediction] = []
            
            // Find correlations for components in this category
            for component in category.components {
                // Search through all grades for this component
                for grade in 3...12 {
                    let mathKey = "Grade_\(grade)_MATH_\(component)"
                    let elaKey = "Grade_\(grade)_ELA_\(component)"
                    
                    // Check math components
                    if let correlations = findTopCorrelations(for: mathKey, in: model) {
                        categoryPredictions.append(contentsOf: correlations)
                    }
                    
                    // Check ELA components
                    if let correlations = findTopCorrelations(for: elaKey, in: model) {
                        categoryPredictions.append(contentsOf: correlations)
                    }
                }
            }
            
            // Sort by correlation strength and take top 10
            categoryPredictions.sort { abs($0.correlationStrength) > abs($1.correlationStrength) }
            categorizedCorrelations[category.name] = Array(categoryPredictions.prefix(10))
        }
        
        await MainActor.run {
            topCorrelationsByCategory = categorizedCorrelations
            isLoadingCorrelations = false
        }
    }
    
    private func findTopCorrelations(for componentKey: String, in model: ValidatedCorrelationModel) -> [CorrelationPrediction]? {
        var predictions: [CorrelationPrediction] = []
        
        // Search through correlation matrix
        for correlationMap in model.correlations {
            let sourceKey = "\(correlationMap.sourceComponent.grade)_\(correlationMap.sourceComponent.subject)_\(correlationMap.sourceComponent.component)"
            
            for correlation in correlationMap.correlations {
                let targetKey = "\(correlation.target.grade)_\(correlation.target.subject)_\(correlation.target.component)"
                
                if (sourceKey.contains(componentKey) || targetKey.contains(componentKey)) && 
                   abs(correlation.correlation) >= minimumCorrelationStrength {
                    
                    // Create prediction
                    let prediction = CorrelationPrediction(
                        id: "\(sourceKey)_to_\(targetKey)",
                        sourceComponent: sourceKey,
                        targetComponent: targetKey,
                        sourceGrade: correlationMap.sourceComponent.grade,
                        targetGrade: correlation.target.grade,
                        correlationStrength: correlation.correlation,
                        confidence: correlation.confidence,
                        pValue: 0.05, // Default since not in model
                        sampleSize: correlation.sampleSize
                    )
                    
                    predictions.append(prediction)
                }
            }
        }
        
        return predictions.isEmpty ? nil : predictions
    }
    
    private func extractGrade(from component: String) -> Int {
        // Extract grade number from component string like "Grade_3_MATH_D1OP"
        let parts = component.split(separator: "_")
        if parts.count > 1, let grade = Int(parts[1]) {
            return grade
        }
        return 0
    }
    
    func generateILPForCorrelation(_ correlation: CorrelationPrediction) async -> IndividualLearningPlan? {
        guard let generator = ilpGenerator else {
            return nil
        }
        
        let student = selectedStudent ?? createSampleStudent()
        
        await MainActor.run {
            isGeneratingILP = true
        }
        
        do {
            // Generate ILP using the correlation data
            guard let model = correlationModel else {
                print("No correlation model available")
                await MainActor.run { isGeneratingILP = false }
                return nil
            }
            
            let ilp = try await generator.generateILP(
                student: student,
                correlationModel: model,
                historicalData: nil
            )
            
            await MainActor.run {
                self.generatedILP = ilp
                isGeneratingILP = false
            }
            
            return ilp
        } catch {
            print("Error generating ILP: \(error)")
            await MainActor.run {
                isGeneratingILP = false
            }
            return nil
        }
    }
    
    func loadStudentPredictions(_ student: StudentAssessmentData) async {
        guard let model = correlationModel,
              let _ = correlationEngine else { return }
        
        self.selectedStudent = student
        
        var predictions: [FuturePrediction] = []
        
        // Analyze student's weak areas using assessment data
        for assessment in student.assessments {
            for (componentKey, score) in assessment.componentScores {
                // Consider scores below 650 as weak areas (typical proficiency threshold)
                if score < 650 {
                    // Find correlations for this weak component
                    let componentId = "Grade_\(student.grade)_\(assessment.subject)_\(componentKey)"
                    if let correlations = findTopCorrelations(for: componentId, in: model) {
                        for correlation in correlations.prefix(3) {
                            let prediction = FuturePrediction(
                                id: UUID().uuidString,
                                student: student,
                                currentWeakness: componentId,
                                predictedStruggle: correlation.targetComponent,
                                predictedGrade: correlation.targetGrade,
                                likelihood: abs(correlation.correlationStrength),
                                confidence: correlation.confidence,
                                timeframe: "\(correlation.targetGrade - student.grade) year(s)"
                            )
                            predictions.append(prediction)
                        }
                    }
                }
            }
        }
        
        // Sort by likelihood
        predictions.sort { $0.likelihood > $1.likelihood }
        
        await MainActor.run {
            studentPredictions = predictions
        }
    }
    
    private func createSampleStudent() -> StudentAssessmentData {
        // Create a sample student for demonstration
        let studentInfo = StudentAssessmentData.StudentInfo(
            msis: "SAMPLE001",
            name: "Sample Student", 
            school: "Sample School",
            district: "Sample District"
        )
        
        return StudentAssessmentData(
            studentInfo: studentInfo,
            year: 2025,
            grade: 5,
            assessments: []
        )
    }
    
    func correlationColor(_ strength: Double) -> Color {
        switch abs(strength) {
        case 0.8...:
            return AppleDesignSystem.SystemPalette.red      // Critical correlation
        case 0.7..<0.8:
            return AppleDesignSystem.SystemPalette.orange   // Strong correlation
        case 0.5..<0.7:
            return AppleDesignSystem.SystemPalette.yellow   // Moderate correlation
        default:
            return .gray     // Weak correlation
        }
    }
    
    func correlationIcon(_ strength: Double) -> String {
        switch abs(strength) {
        case 0.8...:
            return "exclamationmark.3"
        case 0.7..<0.8:
            return "exclamationmark.2"
        case 0.5..<0.7:
            return "exclamationmark"
        default:
            return "info.circle"
        }
    }
}

// MARK: - Supporting Models
struct ReportingCategory: Identifiable {
    let id: String
    let name: String
    let components: [String]
}

struct CorrelationPrediction: Identifiable {
    let id: String
    let sourceComponent: String
    let targetComponent: String
    let sourceGrade: Int
    let targetGrade: Int
    let correlationStrength: Double
    let confidence: Double
    let pValue: Double
    let sampleSize: Int
    
    var description: String {
        "Grade \(sourceGrade) \(sourceComponent) → Grade \(targetGrade) \(targetComponent)"
    }
    
    var strengthDescription: String {
        let percentage = Int(abs(correlationStrength) * 100)
        return "\(percentage)% correlation"
    }
    
    var confidenceDescription: String {
        let percentage = Int(confidence * 100)
        return "\(percentage)% confidence"
    }
}

struct FuturePrediction: Identifiable {
    let id: String
    let student: StudentAssessmentData
    let currentWeakness: String
    let predictedStruggle: String
    let predictedGrade: Int
    let likelihood: Double
    let confidence: Double
    let timeframe: String
    
    var riskLevel: String {
        switch likelihood {
        case 0.9...:
            return "Critical"
        case 0.8..<0.9:
            return "High"
        case 0.7..<0.8:
            return "Moderate"
        default:
            return "Low"
        }
    }
    
    var riskColor: Color {
        switch likelihood {
        case 0.9...:
            return AppleDesignSystem.SystemPalette.red
        case 0.8..<0.9:
            return AppleDesignSystem.SystemPalette.orange
        case 0.7..<0.8:
            return AppleDesignSystem.SystemPalette.yellow
        default:
            return AppleDesignSystem.SystemPalette.green
        }
    }
}