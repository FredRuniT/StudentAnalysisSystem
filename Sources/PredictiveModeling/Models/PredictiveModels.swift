import AnalysisCore
import Foundation

// MARK: - Missing Types for PredictiveModeling

/// PredictionResult represents...
public struct PredictionResult: Sendable {
    /// studentID property
    public let studentID: String
    /// predictedOutcome property
    public let predictedOutcome: String
    /// actualOutcome property
    public let actualOutcome: String?
    /// probability property
    public let probability: Double
    /// confidence property
    public let confidence: Double
    /// wasCorrect property
    public let wasCorrect: Bool?
    
    public init(
        studentID: String,
        predictedOutcome: String,
        actualOutcome: String?,
        probability: Double,
        confidence: Double,
        wasCorrect: Bool?
    ) {
        self.studentID = studentID
        self.predictedOutcome = predictedOutcome
        self.actualOutcome = actualOutcome
        self.probability = probability
        self.confidence = confidence
        self.wasCorrect = wasCorrect
    }
}

/// ConfusionMatrix represents...
public struct ConfusionMatrix: Sendable {
    /// truePositives property
    public let truePositives: Int
    /// trueNegatives property
    public let trueNegatives: Int
    /// falsePositives property
    public let falsePositives: Int
    /// falseNegatives property
    public let falseNegatives: Int
    
    public init(
        truePositives: Int,
        trueNegatives: Int,
        falsePositives: Int,
        falseNegatives: Int
    ) {
        self.truePositives = truePositives
        self.trueNegatives = trueNegatives
        self.falsePositives = falsePositives
        self.falseNegatives = falseNegatives
    }
}

public actor ThresholdCalculator {
    public init() {}
    
    /// calculateOptimalThreshold function description
    public func calculateOptimalThreshold(
        scores: [Double],
        outcomes: [Bool]
    ) async -> Double {
        guard scores.count == outcomes.count, !scores.isEmpty else { return 0.5 }
        
        // Find threshold that maximizes F1 score
        /// bestThreshold property
        var bestThreshold = 0.5
        /// bestF1 property
        var bestF1 = 0.0
        
        /// uniqueScores property
        let uniqueScores = Set(scores).sorted()
        
        for threshold in uniqueScores {
            /// tp property
            var tp = 0, fp = 0, tn = 0, fn = 0
            
            for (score, outcome) in zip(scores, outcomes) {
                /// predicted property
                let predicted = score >= threshold
                switch (predicted, outcome) {
                case (true, true): tp += 1
                case (true, false): fp += 1
                case (false, true): fn += 1
                case (false, false): tn += 1
                }
            }
            
            /// precision property
            let precision = Double(tp) / Double(max(tp + fp, 1))
            /// recall property
            let recall = Double(tp) / Double(max(tp + fn, 1))
            /// f1 property
            let f1 = 2 * precision * recall / max(precision + recall, 0.001)
            
            if f1 > bestF1 {
                bestF1 = f1
                bestThreshold = threshold
            }
        }
        
        return bestThreshold
    }
}

/// ComponentThreshold represents...
public struct ComponentThreshold: Sendable {
    /// component property
    public let component: ComponentIdentifier
    /// riskThreshold property
    public let riskThreshold: Double
    /// successThreshold property
    public let successThreshold: Double
    /// confidence property
    public let confidence: Double
    /// sampleSize property
    public let sampleSize: Int
    
    public init(
        component: ComponentIdentifier,
        riskThreshold: Double,
        successThreshold: Double,
        confidence: Double,
        sampleSize: Int
    ) {
        self.component = component
        self.riskThreshold = riskThreshold
        self.successThreshold = successThreshold
        self.confidence = confidence
        self.sampleSize = sampleSize
    }
}

/// StudentOutcomes represents...
public struct StudentOutcomes: Sendable {
    /// proficientStudents property
    public let proficientStudents: Set<String>
    /// strugglingStudents property
    public let strugglingStudents: Set<String>
    
    public init(proficientStudents: Set<String>, strugglingStudents: Set<String>) {
        self.proficientStudents = proficientStudents
        self.strugglingStudents = strugglingStudents
    }
}

/// Warning represents...
public struct Warning: Sendable {
    /// level property
    public let level: WarningLevel
    /// message property
    public let message: String
    /// confidence property
    public let confidence: Double
    /// recommendations property
    public let recommendations: [String]
    
    public init(
        level: WarningLevel,
        message: String,
        confidence: Double,
        recommendations: [String]
    ) {
        self.level = level
        self.message = message
        self.confidence = confidence
        self.recommendations = recommendations
    }
}

/// WarningLevel description
public enum WarningLevel: String, Sendable {
    case critical = "Critical"
    case high = "High"
    case moderate = "Moderate"
    case low = "Low"
}

// Additional types needed for EarlyWarningSystem
/// RiskFactor represents...
public struct RiskFactor: Sendable {
    /// component property
    public let component: String
    /// severity property
    public let severity: RiskLevel
    /// impact property
    public let impact: Double
    /// description property
    public let description: String
    
    public init(
        component: String,
        severity: RiskLevel,
        impact: Double,
        description: String
    ) {
        self.component = component
        self.severity = severity
        self.impact = impact
        self.description = description
    }
}

// RiskLevel is defined in AnalysisCore

/// Intervention represents...
public struct Intervention: Sendable {
    /// type property
    public let type: InterventionType
    /// priority property
    public let priority: Int
    /// title property
    public let title: String
    /// description property
    public let description: String
    /// targetComponents property
    public let targetComponents: [String]
    /// estimatedDuration property
    public let estimatedDuration: String
    /// resources property
    public let resources: [String]
    
    public init(
        type: InterventionType,
        priority: Int,
        title: String,
        description: String,
        targetComponents: [String],
        estimatedDuration: String,
        resources: [String]
    ) {
        self.type = type
        self.priority = priority
        self.title = title
        self.description = description
        self.targetComponents = targetComponents
        self.estimatedDuration = estimatedDuration
        self.resources = resources
    }
}

/// InterventionType description
public enum InterventionType: String, Sendable {
    case tutoring = "Tutoring"
    case smallGroup = "Small Group"
    case remediation = "Remediation"
    case enrichment = "Enrichment"
    case practice = "Practice"
    case assessment = "Assessment"
    case intensiveSupport = "Intensive Support"
    case targetedIntervention = "Targeted Intervention"
    case regularSupport = "Regular Support"
}

// ComponentPair and TestProvider are defined in AnalysisCore