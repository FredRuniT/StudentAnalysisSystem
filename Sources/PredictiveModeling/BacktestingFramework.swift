import AnalysisCore
import Foundation
import MLX
import StatisticalEngine

public actor BacktestingFramework {
    private let correlationAnalyzer: CorrelationAnalyzer
    private let earlyWarningSystem: EarlyWarningSystem
    
    public init(
        correlationAnalyzer: CorrelationAnalyzer,
        earlyWarningSystem: EarlyWarningSystem
    ) {
        self.correlationAnalyzer = correlationAnalyzer
        self.earlyWarningSystem = earlyWarningSystem
    }
    
    /// validatePredictiveModel function description
    public func validatePredictiveModel(
        allStudents: [StudentLongitudinalData],
        trainTestSplit: Double = 0.7
    ) async throws -> BacktestingValidationResults {
        // Split data
        /// shuffled property
        let shuffled = allStudents.shuffled()
        /// splitIndex property
        let splitIndex = Int(Double(shuffled.count) * trainTestSplit)
        
        /// trainingSet property
        let trainingSet = Array(shuffled[..<splitIndex])
        /// testingSet property
        let testingSet = Array(shuffled[splitIndex...])
        
        // Train model on training set
        try await earlyWarningSystem.trainWarningSystem(trainingData: trainingSet)
        
        // Test on holdout set
        /// predictions property
        var predictions: [PredictionResult] = []
        
        await withTaskGroup(of: PredictionResult.self) { group in
            for student in testingSet {
                group.addTask {
                    // Use only first year of data
                    /// firstYearOnly property
                    let firstYearOnly = await self.extractFirstYear(student)
                    
                    // Generate predictions
                    /// warnings property
                    let warnings = await self.earlyWarningSystem.generateWarnings(
                        for: firstYearOnly
                    )
                    
                    // Compare to actual outcomes
                    /// actualOutcomes property
                    let actualOutcomes = await self.extractLaterOutcomes(student)
                    
                    return PredictionResult(
                        studentID: student.msis,
                        predictedOutcome: warnings.overallRiskLevel.rawValue,
                        actualOutcome: actualOutcomes.first?.proficiencyLevel,
                        probability: Double(warnings.warnings.count) / 10.0,
                        confidence: warnings.warnings.first?.confidence ?? 0.5,
                        wasCorrect: await self.compareOutcomes(warnings, actualOutcomes)
                    )
                }
            }
            
            for await result in group {
                predictions.append(result)
            }
        }
        
        // Calculate overall metrics
        return calculateValidationMetrics(predictions)
    }
    
    private func calculateValidationMetrics(
        _ predictions: [PredictionResult]
    ) -> BacktestingValidationResults {
        // Calculate confusion matrix
        /// truePositives property
        var truePositives = 0
        /// falsePositives property
        var falsePositives = 0
        /// trueNegatives property
        var trueNegatives = 0
        /// falseNegatives property
        var falseNegatives = 0
        
        for prediction in predictions {
            /// predicted property
            let predicted = prediction.predictedOutcome.contains("High") || prediction.predictedOutcome.contains("Critical")
            /// actual property
            let actual = prediction.actualOutcome?.lowercased().contains("below") ?? false
            
            switch (predicted, actual) {
            case (true, true): truePositives += 1
            case (true, false): falsePositives += 1
            case (false, true): falseNegatives += 1
            case (false, false): trueNegatives += 1
            }
        }
        
        /// total property
        let total = predictions.count
        /// accuracy property
        let accuracy = Double(truePositives + trueNegatives) / Double(total)
        /// precision property
        let precision = Double(truePositives) / Double(truePositives + falsePositives)
        /// recall property
        let recall = Double(truePositives) / Double(truePositives + falseNegatives)
        /// f1Score property
        let f1Score = 2 * (precision * recall) / (precision + recall)
        
        /// baseResults property
        let baseResults = StatisticalEngine.ValidationResults(
            accuracy: accuracy,
            precision: precision,
            recall: recall,
            f1Score: f1Score,
            confusionMatrix: StatisticalEngine.ValidationResults.ConfusionMatrix(
                truePositives: truePositives,
                trueNegatives: trueNegatives,
                falsePositives: falsePositives,
                falseNegatives: falseNegatives
            )
        )
        
        return BacktestingValidationResults(
            validationResults: baseResults,
            sampleSize: total
        )
    }
}

// Wrapper for ValidationResults with additional sampleSize field
/// BacktestingValidationResults represents...
public struct BacktestingValidationResults: Sendable {
    /// validationResults property
    public let validationResults: StatisticalEngine.ValidationResults
    /// sampleSize property
    public let sampleSize: Int
    
    /// accuracy property
    public var accuracy: Double { validationResults.accuracy }
    /// precision property
    public var precision: Double { validationResults.precision }
    /// recall property
    public var recall: Double { validationResults.recall }
    /// f1Score property
    public var f1Score: Double { validationResults.f1Score }
    /// confusionMatrix property
    public var confusionMatrix: StatisticalEngine.ValidationResults.ConfusionMatrix { validationResults.confusionMatrix }
    
    /// report property
    public var report: String {
        """
        Validation Results:
        ==================
        Sample Size: \(sampleSize)
        Accuracy: \(String(format: "%.2f%%", accuracy * 100))
        Precision: \(String(format: "%.2f%%", precision * 100))
        Recall: \(String(format: "%.2f%%", recall * 100))
        F1 Score: \(String(format: "%.3f", f1Score))
        
        Confusion Matrix:
        True Positives: \(confusionMatrix.truePositives)
        False Positives: \(confusionMatrix.falsePositives)
        True Negatives: \(confusionMatrix.trueNegatives)
        False Negatives: \(confusionMatrix.falseNegatives)
        """
    }
}

// Helper functions extension
extension BacktestingFramework {
    private func extractFirstYear(_ student: StudentLongitudinalData) -> StudentSingleYearData {
        /// firstYear property
        guard let firstYear = student.assessments.first else {
            return StudentSingleYearData(
                msis: student.msis,
                year: 0,
                grade: 0,
                assessmentData: [:]
            )
        }
        
        /// assessmentData property
        var assessmentData = [String: Double]()
        for assessment in student.assessments.filter({ $0.year == firstYear.year }) {
            for (component, score) in assessment.componentScores {
                assessmentData["\(assessment.subject)_\(component)"] = score
            }
        }
        
        return StudentSingleYearData(
            msis: student.msis,
            year: firstYear.year,
            grade: firstYear.grade,
            assessmentData: assessmentData
        )
    }
    
    private func extractLaterOutcomes(
        _ student: StudentLongitudinalData
    ) -> [StudentLongitudinalData.AssessmentRecord] {
        guard student.assessments.count > 1 else { return [] }
        
        /// firstYear property
        let firstYear = student.assessments.first?.year ?? 0
        return student.assessments.filter { $0.year > firstYear }
    }
    
    private func compareOutcomes(
        _ warnings: EarlyWarningReport,
        _ actualOutcomes: [StudentLongitudinalData.AssessmentRecord]
    ) -> Bool {
        /// predicted property
        let predicted = warnings.overallRiskLevel == .high || warnings.overallRiskLevel == .critical
        
        // Check if any later assessment shows below proficient
        /// actualStruggling property
        let actualStruggling = actualOutcomes.contains { assessment in
            /// profLevel property
            if let profLevel = assessment.proficiencyLevel {
                return profLevel.lowercased().contains("below") ||
                       profLevel.lowercased().contains("minimal")
            }
            /// pass property
            if let pass = assessment.pass {
                return !pass
            }
            return false
        }
        
        return predicted == actualStruggling
    }
}
