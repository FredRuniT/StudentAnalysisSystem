import SwiftUI
import AnalysisCore
import StatisticalEngine
import PredictiveModeling
import IndividualLearningPlan

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
            do {
                // Initialize correlation engine
                correlationEngine = ComponentCorrelationEngine()
                
                // Initialize ILP generator
                ilpGenerator = ILPGenerator()
                
                // Load correlation model if it exists
                await loadCorrelationModel()
            } catch {
                print("Error setting up services: \(error)")
            }
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
        for (key, correlation) in model.correlations {
            if key.contains(componentKey) && abs(correlation.coefficient) >= minimumCorrelationStrength {
                let components = key.split(separator: "_").map(String.init)
                if components.count >= 2 {
                    // Parse the correlation key to extract source and target
                    let sourceComponent = components[0]
                    let targetComponent = components[1]
                    
                    // Create prediction
                    let prediction = CorrelationPrediction(
                        id: key,
                        sourceComponent: sourceComponent,
                        targetComponent: targetComponent,
                        sourceGrade: extractGrade(from: sourceComponent),
                        targetGrade: extractGrade(from: targetComponent),
                        correlationStrength: correlation.coefficient,
                        confidence: correlation.confidence ?? 0,
                        pValue: correlation.pValue,
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
        guard let generator = ilpGenerator,
              let student = selectedStudent ?? createSampleStudent() else {
            return nil
        }
        
        await MainActor.run {
            isGeneratingILP = true
        }
        
        do {
            // Generate ILP using the correlation data
            let ilp = try await generator.generateILP(
                for: student,
                planType: .remediation,
                useBlueprints: true,
                includeGradeProgression: true
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
              let engine = correlationEngine else { return }
        
        self.selectedStudent = student
        
        var predictions: [FuturePrediction] = []
        
        // Analyze student's weak areas
        let weakComponents = student.components.filter { $0.scaledScore < 650 }
        
        for weakComponent in weakComponents {
            // Find correlations for this weak component
            if let correlations = findTopCorrelations(for: weakComponent.componentKey, in: model) {
                for correlation in correlations.prefix(3) {
                    let prediction = FuturePrediction(
                        id: UUID().uuidString,
                        student: student,
                        currentWeakness: weakComponent.componentKey,
                        predictedStruggle: correlation.targetComponent,
                        predictedGrade: correlation.targetGrade,
                        likelihood: abs(correlation.correlationStrength),
                        confidence: correlation.confidence,
                        timeframe: "\(correlation.targetGrade - extractGrade(from: weakComponent.componentKey)) year(s)"
                    )
                    predictions.append(prediction)
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
        StudentAssessmentData(
            msis: "SAMPLE001",
            lastName: "Sample",
            firstName: "Student",
            testGrade: 5,
            testYear: 2025,
            schoolYear: "2024-2025",
            districtName: "Sample District",
            schoolName: "Sample School",
            components: []
        )
    }
    
    func correlationColor(_ strength: Double) -> Color {
        switch abs(strength) {
        case 0.8...:
            return .red      // Critical correlation
        case 0.7..<0.8:
            return .orange   // Strong correlation
        case 0.5..<0.7:
            return .yellow   // Moderate correlation
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
            return .red
        case 0.8..<0.9:
            return .orange
        case 0.7..<0.8:
            return .yellow
        default:
            return .green
        }
    }
}