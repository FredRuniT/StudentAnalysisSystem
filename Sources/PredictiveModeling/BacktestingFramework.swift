import Foundation
import MLX
import AnalysisCore
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
    
    public func validatePredictiveModel(
        allStudents: [StudentLongitudinalData],
        trainTestSplit: Double = 0.7
    ) async throws -> ValidationResults {
        // Split data
        let shuffled = allStudents.shuffled()
        let splitIndex = Int(Double(shuffled.count) * trainTestSplit)
        
        let trainingSet = Array(shuffled[..<splitIndex])
        let testingSet = Array(shuffled[splitIndex...])
        
        // Train model on training set
        try await earlyWarningSystem.trainWarningSystem(trainingData: trainingSet)
        
        // Test on holdout set
        var predictions: [PredictionResult] = []
        
        await withTaskGroup(of: PredictionResult.self) { group in
            for student in testingSet {
                group.addTask {
                    // Use only first year of data
                    let firstYearOnly = await self.extractFirstYear(student)
                    
                    // Generate predictions
                    let warnings = await self.earlyWarningSystem.generateWarnings(
                        for: firstYearOnly
                    )
                    
                    // Compare to actual outcomes
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
    ) -> ValidationResults {
        // Calculate confusion matrix
        var truePositives = 0
        var falsePositives = 0
        var trueNegatives = 0
        var falseNegatives = 0
        
        for prediction in predictions {
            let predicted = prediction.predictedOutcome.contains("High") || prediction.predictedOutcome.contains("Critical")
            let actual = prediction.actualOutcome?.lowercased().contains("below") ?? false
            
            switch (predicted, actual) {
            case (true, true): truePositives += 1
            case (true, false): falsePositives += 1
            case (false, true): falseNegatives += 1
            case (false, false): trueNegatives += 1
            }
        }
        
        let total = predictions.count
        let accuracy = Double(truePositives + trueNegatives) / Double(total)
        let precision = Double(truePositives) / Double(truePositives + falsePositives)
        let recall = Double(truePositives) / Double(truePositives + falseNegatives)
        let f1Score = 2 * (precision * recall) / (precision + recall)
        
        return ValidationResults(
            accuracy: accuracy,
            precision: precision,
            recall: recall,
            f1Score: f1Score,
            confusionMatrix: ConfusionMatrix(
                truePositives: truePositives,
                trueNegatives: trueNegatives,
                falsePositives: falsePositives,
                falseNegatives: falseNegatives
            ),
            sampleSize: total
        )
    }
}

public struct ValidationResults: Sendable {
    public let accuracy: Double
    public let precision: Double
    public let recall: Double
    public let f1Score: Double
    public let confusionMatrix: ConfusionMatrix
    public let sampleSize: Int
    
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
        guard let firstYear = student.assessments.first else {
            return StudentSingleYearData(
                msis: student.msis,
                year: 0,
                grade: 0,
                assessmentData: [:]
            )
        }
        
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
        
        let firstYear = student.assessments.first?.year ?? 0
        return student.assessments.filter { $0.year > firstYear }
    }
    
    private func compareOutcomes(
        _ warnings: EarlyWarningReport,
        _ actualOutcomes: [StudentLongitudinalData.AssessmentRecord]
    ) -> Bool {
        let predicted = warnings.overallRiskLevel == .high || warnings.overallRiskLevel == .critical
        
        // Check if any later assessment shows below proficient
        let actualStruggling = actualOutcomes.contains { assessment in
            if let profLevel = assessment.proficiencyLevel {
                return profLevel.lowercased().contains("below") ||
                       profLevel.lowercased().contains("minimal")
            }
            if let pass = assessment.pass {
                return !pass
            }
            return false
        }
        
        return predicted == actualStruggling
    }
}
