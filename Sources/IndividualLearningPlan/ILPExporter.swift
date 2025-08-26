//
//  ILPExporter.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//

import Foundation

public actor ILPExporter {
    
    public func exportToJSON(_ plan: IndividualLearningPlan) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(plan)
    }
    
    public func exportToMarkdown(_ plan: IndividualLearningPlan) async -> String {
        var markdown = """
        # Individual Learning Plan
        ## Student: \(plan.studentInfo.name) (MSIS: \(plan.studentInfo.msis))
        ### Grade \(plan.studentInfo.grade) | Generated: \(plan.assessmentDate.formatted())
        
        ---
        
        ## Performance Summary
        
        ### Strengths
        \(plan.performanceSummary.strengths.map { "- \($0)" }.joined(separator: "\n"))
        
        ### Areas for Improvement
        \(plan.identifiedGaps.map { "- **\($0.component)**: \($0.severity) (Gap: \($0.gapFromProficient) points)" }.joined(separator: "\n"))
        
        ---
        
        ## Learning Objectives (Scaffolded Approach)
        
        """
        
        for objective in plan.learningObjectives {
            markdown += """
            
            ### Standard \(objective.standardId)
            **\(objective.standardDescription)**
            
            #### Phase 1: Knowledge Building
            \(objective.knowledgeObjectives.map { "- \($0.description) (\($0.estimatedSessions) sessions)" }.joined(separator: "\n"))
            
            #### Phase 2: Understanding Development
            \(objective.understandingObjectives.map { "- \($0.description) (\($0.estimatedSessions) sessions)" }.joined(separator: "\n"))
            
            #### Phase 3: Skill Application
            \(objective.skillsObjectives.map { "- \($0.description) (\($0.estimatedSessions) sessions)" }.joined(separator: "\n"))
            
            **Success Criteria:** \(objective.successCriteria.joined(separator: ", "))
            
            """
        }
        
        markdown += """
        
        ---
        
        ## Intervention Strategies
        
        """
        
        for strategy in plan.interventionStrategies {
            markdown += """
            
            ### Tier \(strategy.tier.rawValue) Intervention
            - **Frequency**: \(strategy.frequency)
            - **Duration**: \(strategy.duration)
            - **Group Size**: \(strategy.groupSize)
            - **Instructional Approach**: \(strategy.instructionalApproach.joined(separator: ", "))
            
            """
        }
        
        if !plan.additionalRecommendations.isEmpty {
            markdown += """
            
            ---
            
            ## Additional Recommendations
            
            """
            
            for bonus in plan.additionalRecommendations {
                markdown += """
                
                ### \(bonus.type.rawValue): \(bonus.standard.standard.id)
                **Rationale**: \(bonus.rationale)
                **Expected Benefit**: \(bonus.expectedBenefit)
                
                """
            }
        }
        
        return markdown
    }
    
    public func exportToCSV(_ plans: [IndividualLearningPlan]) async throws -> String {
        var csv = "MSIS,Name,Grade,Assessment_Date,Overall_Risk,Priority_Standards,Intervention_Tier,Timeline\n"
        
        for plan in plans {
            let priorityStandards = plan.targetStandards.prefix(3).map(\.standard.id).joined(separator: ";")
            let highestTier = plan.interventionStrategies.map(\.tier.rawValue).max() ?? 1
            
            csv += "\"\(plan.studentInfo.msis)\","
            csv += "\"\(plan.studentInfo.name)\","
            csv += "\(plan.studentInfo.grade),"
            csv += "\(plan.assessmentDate.formatted(date: .abbreviated, time: .omitted)),"
            csv += "\"\(plan.predictedOutcomes.first?.riskLevel.rawValue ?? "Unknown")\","
            csv += "\"\(priorityStandards)\","
            csv += "\(highestTier),"
            csv += "\"\(plan.timeline.description)\"\n"
        }
        
        return csv
    }
}
