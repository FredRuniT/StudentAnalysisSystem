import Foundation
import AnalysisCore

public struct ValidationResults: Sendable {
    public let accuracy: Double
    public let precision: Double
    public let recall: Double
    public let f1Score: Double
    public let confusionMatrix: ConfusionMatrix
    
    public init(
        accuracy: Double,
        precision: Double,
        recall: Double,
        f1Score: Double,
        confusionMatrix: ConfusionMatrix
    ) {
        self.accuracy = accuracy
        self.precision = precision
        self.recall = recall
        self.f1Score = f1Score
        self.confusionMatrix = confusionMatrix
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
}

// Model that has been validated for use in production
public struct ValidatedCorrelationModel: Sendable {
    public let correlations: [ComponentCorrelationMap]
    public let validationMetrics: ValidationMetrics
    public let confidenceThreshold: Double
    public let trainedDate: Date
    
    public init(
        correlations: [ComponentCorrelationMap],
        validationMetrics: ValidationMetrics,
        confidenceThreshold: Double,
        trainedDate: Date
    ) {
        self.correlations = correlations
        self.validationMetrics = validationMetrics
        self.confidenceThreshold = confidenceThreshold
        self.trainedDate = trainedDate
    }
}