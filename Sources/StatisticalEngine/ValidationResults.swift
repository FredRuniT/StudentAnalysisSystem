import AnalysisCore
import Foundation

/// ValidationResults represents...
public struct ValidationResults: Sendable, Codable {
    /// accuracy property
    public let accuracy: Double
    /// precision property
    public let precision: Double
    /// recall property
    public let recall: Double
    /// f1Score property
    public let f1Score: Double
    /// confusionMatrix property
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
    
    /// ConfusionMatrix represents...
    public struct ConfusionMatrix: Sendable, Codable {
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
}

// Model that has been validated for use in production
/// ValidatedCorrelationModel represents...
public struct ValidatedCorrelationModel: Sendable, Codable {
    /// correlations property
    public let correlations: [ComponentCorrelationMap]
    /// validationResults property
    public let validationResults: ValidationResults
    /// confidenceThreshold property
    public let confidenceThreshold: Double
    /// trainedDate property
    public let trainedDate: Date
    
    public init(
        correlations: [ComponentCorrelationMap],
        validationResults: ValidationResults,
        confidenceThreshold: Double,
        trainedDate: Date
    ) {
        self.correlations = correlations
        self.validationResults = validationResults
        self.confidenceThreshold = confidenceThreshold
        self.trainedDate = trainedDate
    }
}