import AnalysisCore
import Foundation
import IndividualLearningPlan
import PredictiveModeling
import StatisticalEngine

public actor CSVExporter {
    
    /// exportStudentPlans function description
    public func exportStudentPlans(_ plans: [IndividualLearningPlan]) async throws -> String {
        /// csv property
        var csv = "MSIS,Name,Grade,Assessment_Date,Risk_Level,Priority_Standards,Intervention_Tier,"
        csv += "Knowledge_Objectives,Understanding_Objectives,Skills_Objectives,Timeline\n"
        
        for plan in plans {
            /// row property
            let row = [
                plan.studentInfo.msis.escaped(),
                plan.studentInfo.name.escaped(),
                String(plan.studentInfo.grade),
                plan.assessmentDate.formatted(date: .abbreviated, time: .omitted),
                plan.predictedOutcomes.first?.riskLevel.escaped() ?? "Unknown",
                plan.targetStandards.prefix(3).map(\.standardId).joined(separator: ";").escaped(),
                String(plan.interventionStrategies.first?.tier.rawValue ?? 1),
                plan.learningObjectives.flatMap(\.knowledgeObjectives).count.description,
                plan.learningObjectives.flatMap(\.understandingObjectives).count.description,
                plan.learningObjectives.flatMap(\.skillsObjectives).count.description,
                "\(plan.timeline.milestones.count) milestones".escaped()
            ]
            
            csv += row.joined(separator: ",") + "\n"
        }
        
        return csv
    }
    
    /// exportCorrelations function description
    public func exportCorrelations(_ correlations: [ComponentCorrelationMap]) async throws -> String {
        /// csv property
        var csv = "Source_Grade,Source_Subject,Source_Component,Target_Grade,Target_Subject,Target_Component,"
        csv += "Correlation,Sample_Size,Confidence\n"
        
        for map in correlations {
            for correlation in map.correlations {
                /// row property
                let row = [
                    String(map.sourceComponent.grade),
                    map.sourceComponent.subject.escaped(),
                    map.sourceComponent.component.escaped(),
                    String(correlation.target.grade),
                    correlation.target.subject.escaped(),
                    correlation.target.component.escaped(),
                    String(format: "%.4f", correlation.correlation),
                    String(correlation.sampleSize),
                    String(format: "%.2f%%", correlation.confidence * 100)
                ]
                
                csv += row.joined(separator: ",") + "\n"
            }
        }
        
        return csv
    }
    
    /// exportPredictiveIndicators function description
    public func exportPredictiveIndicators(_ indicators: [PredictiveIndicator]) async throws -> String {
        /// csv property
        var csv = "Source_Component,Source_Grade,Target_Outcome,Target_Grade,Correlation,Confidence,"
        csv += "Risk_Threshold,Success_Threshold,Accuracy,Precision,Recall,Sample_Size,Intervention_Type\n"
        
        for indicator in indicators {
            /// row property
            let row = [
                indicator.sourceComponent.escaped(),
                String(indicator.sourceGrade),
                indicator.targetOutcome.escaped(),
                String(indicator.targetGrade),
                String(format: "%.4f", indicator.correlation),
                String(format: "%.2f%%", indicator.confidence * 100),
                String(format: "%.1f", indicator.riskThreshold),
                String(format: "%.1f", indicator.successThreshold),
                String(format: "%.3f", indicator.validationMetrics.accuracy),
                String(format: "%.3f", indicator.validationMetrics.precision),
                String(format: "%.3f", indicator.validationMetrics.recall),
                String(indicator.validationMetrics.sampleSize),
                indicator.recommendedIntervention.rawValue.escaped()
            ]
            
            csv += row.joined(separator: ",") + "\n"
        }
        
        return csv
    }
    
    /// exportValidationResults function description
    public func exportValidationResults(_ results: ValidationResults) async throws -> String {
        /// csv property
        var csv = "Metric,Value\n"
        
        csv += "Accuracy,\(String(format: "%.4f", results.accuracy))\n"
        csv += "Precision,\(String(format: "%.4f", results.precision))\n"
        csv += "Recall,\(String(format: "%.4f", results.recall))\n"
        csv += "F1_Score,\(String(format: "%.4f", results.f1Score))\n"
        /// sampleSize property
        let sampleSize = results.confusionMatrix.truePositives + 
                        results.confusionMatrix.trueNegatives + 
                        results.confusionMatrix.falsePositives + 
                        results.confusionMatrix.falseNegatives
        csv += "Sample_Size,\(sampleSize)\n"
        csv += "\n"
        csv += "Confusion Matrix\n"
        csv += ",Predicted_Positive,Predicted_Negative\n"
        csv += "Actual_Positive,\(results.confusionMatrix.truePositives),\(results.confusionMatrix.falseNegatives)\n"
        csv += "Actual_Negative,\(results.confusionMatrix.falsePositives),\(results.confusionMatrix.trueNegatives)\n"
        
        return csv
    }
}

extension String {
    /// escaped function description
    func escaped() -> String {
        if self.contains(",") || self.contains("\"") || self.contains("\n") {
            /// escaped property
            let escaped = self.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return self
    }
}