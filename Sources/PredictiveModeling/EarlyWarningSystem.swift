import Foundation
import MLX
import AnalysisCore
import StatisticalEngine

public actor EarlyWarningSystem {
    private let correlationAnalyzer: CorrelationAnalyzer
    private let thresholdCalculator: ThresholdCalculator
    private var warningThresholds: [ComponentThreshold] = []
    
    public init(correlationAnalyzer: CorrelationAnalyzer) {
        self.correlationAnalyzer = correlationAnalyzer
        self.thresholdCalculator = ThresholdCalculator()
    }
    
    public func trainWarningSystem(
        trainingData: [StudentLongitudinalData]
    ) async throws {
        // Identify students who struggled in later years
        let outcomeData = categorizeStudentOutcomes(trainingData)
        
        // Find component thresholds that predict poor outcomes
        warningThresholds = await discoverCriticalThresholds(
            studentData: trainingData,
            outcomes: outcomeData
        )
    }
    
    public func generateWarnings(
        for student: StudentSingleYearData
    ) async -> EarlyWarningReport {
        var warnings: [Warning] = []
        var risks: [RiskFactor] = []
        
        // Check each component against trained thresholds
        for threshold in warningThresholds {
            if let score = student.getComponentScore(threshold.component) {
                if score < threshold.criticalValue {
                    let warning = Warning(
                        component: threshold.component,
                        currentScore: score,
                        threshold: threshold.criticalValue,
                        predictedOutcome: threshold.predictedOutcome,
                        confidence: threshold.confidence,
                        supportingEvidence: threshold.historicalValidation
                    )
                    warnings.append(warning)
                    
                    // Calculate risk level
                    let riskLevel = calculateRiskLevel(
                        score: score,
                        threshold: threshold
                    )
                    risks.append(riskLevel)
                }
            }
        }
        
        // Generate interventions based on warnings
        let interventions = await generateInterventions(warnings: warnings)
        
        return EarlyWarningReport(
            studentID: student.msis,
            assessmentYear: student.year,
            assessmentGrade: student.grade,
            warnings: warnings,
            riskFactors: risks,
            recommendedInterventions: interventions,
            overallRiskLevel: calculateOverallRisk(risks)
        )
    }
    
    private func discoverCriticalThresholds(
        studentData: [StudentLongitudinalData],
        outcomes: StudentOutcomes
    ) async -> [ComponentThreshold] {
        var thresholds: [ComponentThreshold] = []
        
        // Get all unique components from the data
        let allComponents = extractAllComponents(from: studentData)
        
        await withTaskGroup(of: ComponentThreshold?.self) { group in
            for component in allComponents {
                group.addTask {
                    return await self.findOptimalThreshold(
                        for: component,
                        studentData: studentData,
                        outcomes: outcomes
                    )
                }
            }
            
            for await threshold in group {
                if let threshold = threshold {
                    thresholds.append(threshold)
                }
            }
        }
        
        // Sort by predictive power
        return thresholds.sorted { $0.confidence > $1.confidence }
    }
    
    private func findOptimalThreshold(
        for component: ComponentIdentifier,
        studentData: [StudentLongitudinalData],
        outcomes: StudentOutcomes
    ) async -> ComponentThreshold? {
        // Use MLX for efficient computation
        let scores = extractComponentScores(component, from: studentData)
        let outcomeLabels = mapToOutcomeLabels(scores, outcomes)
        
        guard scores.count >= 50 else { return nil }
        
        return await Task.detached(priority: .userInitiated) {
            let mlxScores = MLX.array(scores.map { $0.value })
            let mlxOutcomes = MLX.array(outcomeLabels.map { $0 ? 1.0 : 0.0 })
            
            // Find optimal threshold using ROC analysis
            var bestThreshold = 0.0
            var bestF1Score = 0.0
            
            let percentiles = [10, 20, 25, 30, 35, 40, 45, 50, 60, 70]
            
            for percentile in percentiles {
                let threshold = MLX.percentile(mlxScores, q: Double(percentile)).item(Double.self)
                
                // Calculate performance metrics
                let predictions = mlxScores.map { $0 < threshold ? 1.0 : 0.0 }
                let f1Score = self.calculateF1Score(
                    predictions: predictions,
                    actual: outcomeLabels
                )
                
                if f1Score > bestF1Score {
                    bestF1Score = f1Score
                    bestThreshold = threshold
                }
            }
            
            // Validate on holdout set
            let validation = self.validateThreshold(
                threshold: bestThreshold,
                component: component,
                studentData: studentData
            )
            
            return ComponentThreshold(
                component: component.toString(),
                criticalValue: bestThreshold,
                confidence: validation.accuracy,
                predictedOutcome: "Below proficient in future assessment",
                historicalValidation: validation
            )
        }.value
    }
}

public struct EarlyWarningReport: Sendable {
    public let studentID: String
    public let assessmentYear: Int
    public let assessmentGrade: Int
    public let warnings: [Warning]
    public let riskFactors: [RiskFactor]
    public let recommendedInterventions: [Intervention]
    public let overallRiskLevel: RiskLevel
}

public enum RiskLevel: String, Sendable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case critical = "Critical"
}
