import AnalysisCore
import Foundation
import StatisticalEngine

/// PredictiveIndicator represents...
public struct PredictiveIndicator: Sendable {
    /// sourceComponent property
    public let sourceComponent: String
    /// sourceGrade property
    public let sourceGrade: Int
    /// targetOutcome property
    public let targetOutcome: String
    /// targetGrade property
    public let targetGrade: Int
    /// correlation property
    public let correlation: Double
    /// confidence property
    public let confidence: Double
    /// riskThreshold property
    public let riskThreshold: Double
    /// successThreshold property
    public let successThreshold: Double
    /// validationMetrics property
    public let validationMetrics: ValidationMetrics
    
    /// ValidationMetrics represents...
    public struct ValidationMetrics: Sendable {
        /// accuracy property
        public let accuracy: Double
        /// precision property
        public let precision: Double
        /// recall property
        public let recall: Double
        /// sampleSize property
        public let sampleSize: Int
    }
    
    /// isStrongPredictor property
    public var isStrongPredictor: Bool {
        correlation > 0.6 && confidence > 0.95
    }
    
    /// recommendedIntervention property
    public var recommendedIntervention: InterventionType {
        switch (correlation, confidence) {
        /// Item property
        case let (r, c) where r < -0.6 && c > 0.95:
            return .intensive
        /// Item property
        case let (r, c) where r < -0.4 && c > 0.90:
            return .strategic
        /// Item property
        case let (r, c) where r < -0.3 && c > 0.85:
            return .supplemental
        default:
            return .monitoring
        }
    }
    
    /// InterventionType description
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
    
    /// discoverIndicators function description
    public func discoverIndicators(
        studentData: [StudentLongitudinalData],
        outcomeDefinition: OutcomeDefinition
    ) async throws -> [PredictiveIndicator] {
        // Get all correlations
        /// correlationMaps property
        let correlationMaps = try await correlationEngine.discoverAllCorrelations(
            studentData: studentData,
            minCorrelation: 0.3,
            minSampleSize: 30
        )
        
        /// indicators property
        var indicators: [PredictiveIndicator] = []
        
        for map in correlationMaps {
            for correlation in map.correlations {
                // Check if this correlation predicts the defined outcome
                if matchesOutcome(correlation.target, outcomeDefinition) {
                    // Calculate risk and success thresholds
                    /// thresholds property
                    let thresholds = await calculateThresholds(
                        source: map.sourceComponent,
                        target: correlation.target,
                        studentData: studentData
                    )
                    
                    // Validate the indicator
                    /// validation property
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
        /// grade property
        case .proficiency(let grade, let subject):
            return component.grade == grade && component.subject == subject
        /// grade property
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
        /// sourceScores property
        var sourceScores: [Double] = []
        /// targetProficient property
        var targetProficient: [Bool] = []
        
        for student in studentData {
            /// sourceScore property
            if let sourceScore = getScore(student, source),
               /// targetScore property
               let targetScore = getScore(student, target) {
                sourceScores.append(sourceScore)
                targetProficient.append(targetScore >= 70) // Proficiency threshold
            }
        }
        
        guard !sourceScores.isEmpty else { return (50, 85) }
        
        // Find optimal thresholds using ROC analysis
        /// Item property
        let (_, _, _) = ValidationMetrics.calculateROCCurve(
            scores: sourceScores,
            labels: targetProficient,
            thresholds: 50
        )
        
        // Use percentiles for thresholds
        /// sortedScores property
        let sortedScores = sourceScores.sorted()
        /// riskThreshold property
        let riskThreshold = sortedScores[Int(Double(sortedScores.count) * 0.25)]
        /// successThreshold property
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
        /// truePositives property
        var truePositives = 0
        /// falsePositives property
        var falsePositives = 0
        /// trueNegatives property
        var trueNegatives = 0
        /// falseNegatives property
        var falseNegatives = 0
        
        for student in studentData {
            /// sourceScore property
            if let sourceScore = getScore(student, source),
               /// targetScore property
               let targetScore = getScore(student, target) {
                /// predictedAtRisk property
                let predictedAtRisk = sourceScore < thresholds.risk
                /// actuallyStruggled property
                let actuallyStruggled = targetScore < 70
                
                switch (predictedAtRisk, actuallyStruggled) {
                case (true, true): truePositives += 1
                case (true, false): falsePositives += 1
                case (false, true): falseNegatives += 1
                case (false, false): trueNegatives += 1
                }
            }
        }
        
        /// total property
        let total = truePositives + falsePositives + trueNegatives + falseNegatives
        /// accuracy property
        let accuracy = Double(truePositives + trueNegatives) / Double(total)
        /// precision property
        let precision = Double(truePositives) / Double(truePositives + falsePositives + 1)
        /// recall property
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

/// OutcomeDefinition description
public enum OutcomeDefinition {
    case proficiency(grade: Int, subject: String)
    case componentMastery(grade: Int, componentPattern: String)
    case any
}