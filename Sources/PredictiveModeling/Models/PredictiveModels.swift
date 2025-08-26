import Foundation
import AnalysisCore

// MARK: - Missing Types for PredictiveModeling

public struct PredictionResult: Sendable {
    public let studentID: String
    public let predictedOutcome: String
    public let actualOutcome: String?
    public let probability: Double
    public let confidence: Double
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

public struct ConfusionMatrix: Sendable {
    public let truePositives: Int
    public let trueNegatives: Int
    public let falsePositives: Int
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
    
    public func calculateOptimalThreshold(
        scores: [Double],
        outcomes: [Bool]
    ) async -> Double {
        guard scores.count == outcomes.count, !scores.isEmpty else { return 0.5 }
        
        // Find threshold that maximizes F1 score
        var bestThreshold = 0.5
        var bestF1 = 0.0
        
        let uniqueScores = Set(scores).sorted()
        
        for threshold in uniqueScores {
            var tp = 0, fp = 0, tn = 0, fn = 0
            
            for (score, outcome) in zip(scores, outcomes) {
                let predicted = score >= threshold
                switch (predicted, outcome) {
                case (true, true): tp += 1
                case (true, false): fp += 1
                case (false, true): fn += 1
                case (false, false): tn += 1
                }
            }
            
            let precision = Double(tp) / Double(max(tp + fp, 1))
            let recall = Double(tp) / Double(max(tp + fn, 1))
            let f1 = 2 * precision * recall / max(precision + recall, 0.001)
            
            if f1 > bestF1 {
                bestF1 = f1
                bestThreshold = threshold
            }
        }
        
        return bestThreshold
    }
}

public struct ComponentThreshold: Sendable {
    public let component: ComponentIdentifier
    public let riskThreshold: Double
    public let successThreshold: Double
    public let confidence: Double
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

public struct StudentOutcomes: Sendable {
    public let proficientStudents: Set<String>
    public let strugglingStudents: Set<String>
    
    public init(proficientStudents: Set<String>, strugglingStudents: Set<String>) {
        self.proficientStudents = proficientStudents
        self.strugglingStudents = strugglingStudents
    }
}

public struct Warning: Sendable {
    public let level: WarningLevel
    public let message: String
    public let confidence: Double
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

public enum WarningLevel: String, Sendable {
    case critical = "Critical"
    case high = "High"
    case moderate = "Moderate"
    case low = "Low"
}

// Additional types needed for EarlyWarningSystem
public struct RiskFactor: Sendable {
    public let component: String
    public let severity: RiskLevel
    public let impact: Double
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

public struct Intervention: Sendable {
    public let type: InterventionType
    public let priority: Int
    public let title: String
    public let description: String
    public let targetComponents: [String]
    public let estimatedDuration: String
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

public enum InterventionType: String, Sendable {
    case tutoring = "Tutoring"
    case smallGroup = "Small Group"
    case remediation = "Remediation"
    case enrichment = "Enrichment"
    case practice = "Practice"
    case assessment = "Assessment"
}

// ComponentPair and TestProvider are defined in AnalysisCore