//
//  ILPExporter.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//

import Foundation

public actor ILPExporter {
    
    public init() {}
    
    // MARK: - JSON Export
    
    public func exportToJSON(_ plan: IndividualLearningPlan) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(plan)
    }
    
    // MARK: - Markdown Export
    
    public func exportToMarkdown(_ plan: IndividualLearningPlan) async -> String {
        var markdown = """
        # Individual Learning Plan
        ## Student: \(plan.studentInfo.name) (MSIS: \(plan.studentInfo.msis))
        ### Grade \(plan.studentInfo.grade) | Generated: \(plan.assessmentDate.formatted())
        
        ---
        
        ## Performance Summary
        **Overall Score**: \(String(format: "%.1f", plan.performanceSummary.overallScore))
        **Proficiency Level**: \(plan.performanceSummary.proficiencyLevel.rawValue)
        
        ### Strengths
        \(plan.performanceSummary.strengthAreas.map { "- \($0)" }.joined(separator: "\n"))
        
        ### Areas for Improvement
        \(plan.identifiedGaps.map { "- **\($0.component)**: Score: \(String(format: "%.1f", $0.score)) (Gap: \(String(format: "%.1f", $0.gap)) points)" }.joined(separator: "\n"))
        
        ---
        
        ## Target Standards
        
        """
        
        for (index, standard) in plan.targetStandards.enumerated() {
            markdown += """
            
            \(index + 1). **\(standard.standardId)** (Priority: \(standard.priority))
               - Rationale: \(standard.rationale)
            
            """
        }
        
        markdown += """
        
        ---
        
        ## Learning Objectives (Scaffolded Approach)
        
        """
        
        for objective in plan.learningObjectives {
            markdown += """
            
            ### Standard \(objective.standardId)
            **\(objective.standardDescription)**
            
            Current Level: \(objective.currentLevel.rawValue) → Target Level: \(objective.targetLevel.rawValue)
            
            #### Phase 1: Knowledge Building
            \(objective.knowledgeObjectives.map { "- \($0.description) (\($0.estimatedSessions) sessions)" }.joined(separator: "\n"))
            
            #### Phase 2: Understanding Development
            \(objective.understandingObjectives.map { "- \($0.description) (\($0.estimatedSessions) sessions)" }.joined(separator: "\n"))
            
            #### Phase 3: Skill Application
            \(objective.skillsObjectives.map { "- \($0.description) (\($0.estimatedSessions) sessions)" }.joined(separator: "\n"))
            
            **Keywords**: \(objective.keywords.joined(separator: ", "))
            **Success Criteria**: \(objective.successCriteria.joined(separator: ", "))
            **Estimated Timeframe**: \(objective.estimatedTimeframe) weeks
            
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
            - **Focus Standards**: \(strategy.focus.joined(separator: ", "))
            - **Instructional Approach**: 
              \(strategy.instructionalApproach.map { "  - \($0)" }.joined(separator: "\n"))
            - **Materials**: \(strategy.materials.joined(separator: ", "))
            - **Progress Monitoring**: \(strategy.progressMonitoring)
            
            """
        }
        
        markdown += """
        
        ---
        
        ## Predicted Outcomes
        
        """
        
        for risk in plan.predictedOutcomes {
            markdown += """
            
            ### \(risk.area)
            - **Risk Level**: \(risk.riskLevel)
            - **Confidence**: \(String(format: "%.0f%%", risk.confidence * 100))
            - **Recommendations**:
              \(risk.recommendations.map { "  - \($0)" }.joined(separator: "\n"))
            
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
                **Description**: \(bonus.standard.standard.description)
                **Rationale**: \(bonus.rationale)
                **Expected Benefit**: \(bonus.expectedBenefit)
                
                """
            }
        }
        
        markdown += """
        
        ---
        
        ## Timeline
        
        **Start Date**: \(plan.timeline.startDate.formatted(date: .abbreviated, time: .omitted))
        **End Date**: \(plan.timeline.endDate.formatted(date: .abbreviated, time: .omitted))
        
        ### Milestones
        
        """
        
        for milestone in plan.timeline.milestones {
            markdown += """
            - **\(milestone.date.formatted(date: .abbreviated, time: .omitted))**: \(milestone.description) (\(milestone.assessmentType))
            
            """
        }
        
        return markdown
    }
    
    // MARK: - CSV Export
    
    public func exportToCSV(_ plans: [IndividualLearningPlan]) async throws -> String {
        var csv = "MSIS,Name,Grade,Assessment_Date,Overall_Score,Proficiency_Level,Priority_Standards,Intervention_Tier,Risk_Level,Timeline_Duration\n"
        
        for plan in plans {
            let priorityStandards = plan.targetStandards.prefix(3).map(\.standardId).joined(separator: ";")
            let highestTier = plan.interventionStrategies.map(\.tier.rawValue).max() ?? 1
            let riskLevel = plan.predictedOutcomes.first?.riskLevel ?? "Unknown"
            
            let timelineDuration = calculateTimelineDuration(plan.timeline)
            
            csv += "\"\(plan.studentInfo.msis)\","
            csv += "\"\(plan.studentInfo.name)\","
            csv += "\(plan.studentInfo.grade),"
            csv += "\(plan.assessmentDate.formatted(date: .abbreviated, time: .omitted)),"
            csv += "\(String(format: "%.1f", plan.performanceSummary.overallScore)),"
            csv += "\"\(plan.performanceSummary.proficiencyLevel.rawValue)\","
            csv += "\"\(priorityStandards)\","
            csv += "\(highestTier),"
            csv += "\"\(riskLevel)\","
            csv += "\"\(timelineDuration)\"\n"
        }
        
        return csv
    }
    
    // MARK: - HTML Export (for better formatting)
    
    public func exportToHTML(_ plan: IndividualLearningPlan) async -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <title>ILP - \(plan.studentInfo.name)</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; }
                h1 { color: #2c3e50; }
                h2 { color: #34495e; border-bottom: 2px solid #3498db; padding-bottom: 5px; }
                h3 { color: #7f8c8d; }
                .strength { color: #27ae60; }
                .weakness { color: #e74c3c; }
                .info-box { background: #ecf0f1; padding: 15px; border-radius: 5px; margin: 10px 0; }
                .timeline { background: #f8f9fa; padding: 10px; border-left: 3px solid #3498db; margin: 10px 0; }
                table { border-collapse: collapse; width: 100%; margin: 20px 0; }
                th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
                th { background-color: #3498db; color: white; }
                tr:nth-child(even) { background-color: #f2f2f2; }
            </style>
        </head>
        <body>
            <h1>Individual Learning Plan</h1>
            <div class="info-box">
                <strong>Student:</strong> \(plan.studentInfo.name) (MSIS: \(plan.studentInfo.msis))<br>
                <strong>Grade:</strong> \(plan.studentInfo.grade)<br>
                <strong>Generated:</strong> \(plan.assessmentDate.formatted())<br>
                <strong>Overall Score:</strong> \(String(format: "%.1f", plan.performanceSummary.overallScore))<br>
                <strong>Proficiency Level:</strong> \(plan.performanceSummary.proficiencyLevel.rawValue)
            </div>
            
            <h2>Performance Analysis</h2>
            <h3 class="strength">Strengths</h3>
            <ul>
                \(plan.performanceSummary.strengthAreas.map { "<li>\($0)</li>" }.joined())
            </ul>
            
            <h3 class="weakness">Areas for Improvement</h3>
            <ul>
                \(plan.identifiedGaps.map { "<li><strong>\($0.component)</strong>: Gap of \(String(format: "%.1f", $0.gap)) points</li>" }.joined())
            </ul>
            
            <h2>Intervention Plan</h2>
            <table>
                <tr>
                    <th>Tier</th>
                    <th>Frequency</th>
                    <th>Duration</th>
                    <th>Group Size</th>
                    <th>Progress Monitoring</th>
                </tr>
                \(plan.interventionStrategies.map { strategy in
                    """
                    <tr>
                        <td>Tier \(strategy.tier.rawValue)</td>
                        <td>\(strategy.frequency)</td>
                        <td>\(strategy.duration)</td>
                        <td>\(strategy.groupSize)</td>
                        <td>\(strategy.progressMonitoring)</td>
                    </tr>
                    """
                }.joined())
            </table>
            
            <h2>Timeline</h2>
            <div class="timeline">
                <strong>Duration:</strong> \(calculateTimelineDuration(plan.timeline))<br>
                <strong>Start:</strong> \(plan.timeline.startDate.formatted(date: .abbreviated, time: .omitted))<br>
                <strong>End:</strong> \(plan.timeline.endDate.formatted(date: .abbreviated, time: .omitted))
            </div>
        </body>
        </html>
        """
    }
    
    // MARK: - Summary Report for Multiple Students
    
    public func generateSummaryReport(_ plans: [IndividualLearningPlan]) async -> String {
        let strugglingCount = plans.filter { $0.performanceSummary.proficiencyLevel == .minimal || 
                                           $0.performanceSummary.proficiencyLevel == .belowBasic }.count
        let proficientCount = plans.filter { $0.performanceSummary.proficiencyLevel == .proficient }.count
        let advancedCount = plans.filter { $0.performanceSummary.proficiencyLevel == .advanced }.count
        
        let tier3Count = plans.filter { $0.interventionStrategies.contains { $0.tier == .intensive } }.count
        let tier2Count = plans.filter { $0.interventionStrategies.contains { $0.tier == .strategic } }.count
        
        return """
        # Student Analysis System - Summary Report
        
        ## Overview
        - **Total Students Analyzed**: \(plans.count)
        - **Date Generated**: \(Date().formatted())
        
        ## Performance Distribution
        - **Advanced**: \(advancedCount) students (\(String(format: "%.1f%%", Double(advancedCount) / Double(plans.count) * 100)))
        - **Proficient**: \(proficientCount) students (\(String(format: "%.1f%%", Double(proficientCount) / Double(plans.count) * 100)))
        - **Below Proficient**: \(strugglingCount) students (\(String(format: "%.1f%%", Double(strugglingCount) / Double(plans.count) * 100)))
        
        ## Intervention Needs
        - **Tier 3 (Intensive)**: \(tier3Count) students
        - **Tier 2 (Strategic)**: \(tier2Count) students
        - **Tier 1 (Universal/Enrichment)**: \(plans.count - tier3Count - tier2Count) students
        
        ## Common Areas of Need
        \(identifyCommonGaps(from: plans))
        
        ## Common Areas of Strength
        \(identifyCommonStrengths(from: plans))
        
        ## Resource Requirements
        - **Intervention Specialists Needed**: \(calculateStaffNeeds(plans))
        - **Small Group Sessions per Week**: \(calculateSessionNeeds(plans))
        
        ## Recommendations
        1. Prioritize intensive intervention for \(tier3Count) students showing critical gaps
        2. Implement strategic small-group instruction for \(tier2Count) students
        3. Provide enrichment opportunities for \(advancedCount) advanced students
        4. Monitor progress weekly using prescribed assessment tools
        5. Engage parents with take-home support materials
        """
    }
    
    // MARK: - Helper Functions
    
    private func calculateTimelineDuration(_ timeline: Timeline) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: timeline.startDate, to: timeline.endDate)
        let weeks = components.weekOfYear ?? 0
        return "\(weeks) weeks"
    }
    
    private func identifyCommonGaps(from plans: [IndividualLearningPlan]) -> String {
        var gapCounts = [String: Int]()
        
        for plan in plans {
            for gap in plan.identifiedGaps {
                let component = gap.component
                gapCounts[component, default: 0] += 1
            }
        }
        
        let sortedGaps = gapCounts.sorted { $0.value > $1.value }.prefix(5)
        return sortedGaps.map { "- \($0.key): \($0.value) students" }.joined(separator: "\n")
    }
    
    private func identifyCommonStrengths(from plans: [IndividualLearningPlan]) -> String {
        var strengthCounts = [String: Int]()
        
        for plan in plans {
            for strength in plan.performanceSummary.strengthAreas {
                strengthCounts[strength, default: 0] += 1
            }
        }
        
        let sortedStrengths = strengthCounts.sorted { $0.value > $1.value }.prefix(5)
        return sortedStrengths.map { "- \($0.key): \($0.value) students" }.joined(separator: "\n")
    }
    
    private func calculateStaffNeeds(_ plans: [IndividualLearningPlan]) -> String {
        let tier3Count = plans.filter { $0.interventionStrategies.contains { $0.tier == .intensive } }.count
        let tier2Count = plans.filter { $0.interventionStrategies.contains { $0.tier == .strategic } }.count
        
        // Rough calculation: 1 specialist per 5 tier 3 students, 1 per 10 tier 2 students
        let specialistsNeeded = Int(ceil(Double(tier3Count) / 5.0 + Double(tier2Count) / 10.0))
        return "\(specialistsNeeded) specialists"
    }
    
    private func calculateSessionNeeds(_ plans: [IndividualLearningPlan]) -> Int {
        var totalSessions = 0
        
        for plan in plans {
            for strategy in plan.interventionStrategies {
                switch strategy.frequency.lowercased() {
                case let freq where freq.contains("daily"):
                    totalSessions += 5
                case let freq where freq.contains("3x"):
                    totalSessions += 3
                case let freq where freq.contains("2x"):
                    totalSessions += 2
                default:
                    totalSessions += 1
                }
            }
        }
        
        return totalSessions
    }
}