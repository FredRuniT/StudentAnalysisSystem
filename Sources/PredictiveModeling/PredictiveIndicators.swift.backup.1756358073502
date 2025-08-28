import Foundation
import AnalysisCore
import StatisticalEngine

public struct PredictiveIndicator: Sendable {
    public let sourceComponent: String
    public let sourceGrade: Int
    public let targetOutcome: String
    public let targetGrade: Int
    public let correlation: Double
    public let confidence: Double
    public let riskThreshold: Double
    public let successThreshold: Double
    public let validationMetrics: ValidationMetrics
    
    public struct ValidationMetrics: Sendable {
        public let accuracy: Double
        public let precision: Double
        public let recall: Double
        public let sampleSize: Int
    }
    
    public var isStrongPredictor: Bool {
        correlation > 0.6 && confidence > 0.95
    }
    
    public var recommendedIntervention: InterventionType {
        switch (correlation, confidence) {
        case let (r, c) where r < -0.6 && c > 0.95:
            return .intensive
        case let (r, c) where r < -0.4 && c > 0.90:
            return .strategic
        case let (r, c) where r < -0.3 && c > 0.85:
            return .supplemental
        default:
            return .monitoring
        }
    }
    
    public enum InterventionType: String, Sendable {
        case intensive = "Intensive (Tier 3)"
        case strategic = "Strategic (Tier 2)"
        case supplemental = "Supplemental (Tier 1)"
        case monitoring = "Progress Monitoring"
    }
}

public actor PredictiveIndicatorDiscovery {
    private let correlationEngine: ComponentCorrelationEngine
    
    public init(correlationEngine: ComponentCorrelationEngine) {
        self.correlationEngine = correlationEngine
    }
    
    public func discoverIndicators(
        studentData: [StudentLongitudinalData],
        outcomeDefinition: OutcomeDefinition
    ) async throws -> [PredictiveIndicator] {
        // Get all correlations
        let correlationMaps = try await correlationEngine.discoverAllCorrelations(
            studentData: studentData,
            minCorrelation: 0.3,
            minSampleSize: 30
        )
        
        var indicators: [PredictiveIndicator] = []
        
        for map in correlationMaps {
            for correlation in map.correlations {
                // Check if this correlation predicts the defined outcome
                if matchesOutcome(correlation.target, outcomeDefinition) {
                    // Calculate risk and success thresholds
                    let thresholds = await calculateThresholds(
                        source: map.sourceComponent,
                        target: correlation.target,
                        studentData: studentData
                    )
                    
                    // Validate the indicator
                    let validation = await validateIndicator(
                        source: map.sourceComponent,
                        target: correlation.target,
                        thresholds: thresholds,
                        studentData: studentData
                    )
                    
                    indicators.append(
                        PredictiveIndicator(
                            sourceComponent: map.sourceComponent.component,
                            sourceGrade: map.sourceComponent.grade,
                            targetOutcome: correlation.target.description,
                            targetGrade: correlation.target.grade,
                            correlation: correlation.correlation,
                            confidence: correlation.confidence,
                            riskThreshold: thresholds.risk,
                            successThreshold: thresholds.success,
                            validationMetrics: validation
                        )
                    )
                }
            }
        }
        
        return indicators.sorted { abs($0.correlation) > abs($1.correlation) }
    }
    
    private func matchesOutcome(
        _ component: ComponentIdentifier,
        _ outcome: OutcomeDefinition
    ) -> Bool {
        switch outcome {
        case .proficiency(let grade, let subject):
            return component.grade == grade && component.subject == subject
        case .componentMastery(let grade, let componentPattern):
            return component.grade == grade && component.component.contains(componentPattern)
        case .any:
            return true
        }
    }
    
    private func calculateThresholds(
        source: ComponentIdentifier,
        target: ComponentIdentifier,
        studentData: [StudentLongitudinalData]
    ) async -> (risk: Double, success: Double) {
        // Extract paired scores
        var sourceScores: [Double] = []
        var targetProficient: [Bool] = []
        
        for student in studentData {
            if let sourceScore = getScore(student, source),
               let targetScore = getScore(student, target) {
                sourceScores.append(sourceScore)
                targetProficient.append(targetScore >= 70) // Proficiency threshold
            }
        }
        
        guard !sourceScores.isEmpty else { return (50, 85) }
        
        // Find optimal thresholds using ROC analysis
        let (_, _, _) = ValidationMetrics.calculateROCCurve(
            scores: sourceScores,
            labels: targetProficient,
            thresholds: 50
        )
        
        // Use percentiles for thresholds
        let sortedScores = sourceScores.sorted()
        let riskThreshold = sortedScores[Int(Double(sortedScores.count) * 0.25)]
        let successThreshold = sortedScores[Int(Double(sortedScores.count) * 0.75)]
        
        return (riskThreshold, successThreshold)
    }
    
    private func validateIndicator(
        source: ComponentIdentifier,
        target: ComponentIdentifier,
        thresholds: (risk: Double, success: Double),
        studentData: [StudentLongitudinalData]
    ) async -> PredictiveIndicator.ValidationMetrics {
        // Simple validation (should use proper cross-validation)
        var truePositives = 0
        var falsePositives = 0
        var trueNegatives = 0
        var falseNegatives = 0
        
        for student in studentData {
            if let sourceScore = getScore(student, source),
               let targetScore = getScore(student, target) {
                let predictedAtRisk = sourceScore < thresholds.risk
                let actuallyStruggled = targetScore < 70
                
                switch (predictedAtRisk, actuallyStruggled) {
                case (true, true): truePositives += 1
                case (true, false): falsePositives += 1
                case (false, true): falseNegatives += 1
                case (false, false): trueNegatives += 1
                }
            }
        }
        
        let total = truePositives + falsePositives + trueNegatives + falseNegatives
        let accuracy = Double(truePositives + trueNegatives) / Double(total)
        let precision = Double(truePositives) / Double(truePositives + falsePositives + 1)
        let recall = Double(truePositives) / Double(truePositives + falseNegatives + 1)
        
        return PredictiveIndicator.ValidationMetrics(
            accuracy: accuracy,
            precision: precision,
            recall: recall,
            sampleSize: total
        )
    }
    
    private func getScore(_ student: StudentLongitudinalData, _ component: ComponentIdentifier) -> Double? {
        student.assessments.first { assessment in
            assessment.grade == component.grade &&
            assessment.subject == component.subject
        }?.componentScores[component.component]
    }
}

public enum OutcomeDefinition {
    case proficiency(grade: Int, subject: String)
    case componentMastery(grade: Int, componentPattern: String)
    case any
}