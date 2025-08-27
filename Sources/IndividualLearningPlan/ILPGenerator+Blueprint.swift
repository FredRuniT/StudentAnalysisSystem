//
//  ILPGenerator+Blueprint.swift
//  StudentAnalysisSystem
//
//  Blueprint integration extension for ILP Generation
//

import Foundation
import AnalysisCore
import PredictiveModeling
import StatisticalEngine

extension ILPGenerator {
    
    // MARK: - Blueprint-Enhanced ILP Generation
    
    /// Generate remediation ILP with blueprint integration
    func generateRemediationILPWithBlueprints(
        student: StudentAssessmentData,
        performanceAnalysis: PerformanceAnalysis,
        correlationModel: ValidatedCorrelationModel,
        progressionPlan: StudentProgressionPlan?
    ) async throws -> IndividualLearningPlan {
        
        // Use progression plan if available
        if let plan = progressionPlan {
            return await generateILPFromProgressionPlan(
                student: student,
                performanceAnalysis: performanceAnalysis,
                progressionPlan: plan,
                type: TimelineType.remediation
            )
        }
        
        // Fallback to standard remediation with blueprint mapping
        let weakAreas = identifyWeakAreas(performanceAnalysis)
        
        // Map weak areas to blueprint standards
        let targetStandardIds = await mapWeakAreasToStandardsWithBlueprints(
            weakAreas,
            grade: student.grade,
            subject: student.assessments.first?.subject ?? "MATH"
        )
        
        // Convert to TargetStandard format
        let targetStandards = targetStandardIds.enumerated().map { index, standardId in
            TargetStandard(
                standardId: standardId,
                priority: index + 1,
                rationale: "Addresses weakness identified in assessment"
            )
        }
        
        // Generate objectives based on blueprint expectations  
        let learningObjectives = await generateBlueprintBasedObjectives(
            standards: targetStandardIds,
            studentLevel: performanceAnalysis.proficiencyLevel,
            grade: student.grade
        )
        
        return IndividualLearningPlan(
            studentInfo: createStudentInfo(from: student),
            assessmentDate: Date(),
            performanceSummary: performanceAnalysis,
            identifiedGaps: weakAreas,
            targetStandards: targetStandards,
            learningObjectives: learningObjectives,
            interventionStrategies: createRemediationStrategies(
                objectives: learningObjectives,
                risks: []
            ),
            additionalRecommendations: [],
            predictedOutcomes: [],
            timeline: generateTimeline(
                startDate: Date(),
                objectives: learningObjectives,
                type: TimelineType.remediation
            )
        )
    }
    
    /// Generate enrichment ILP with blueprint integration
    func generateEnrichmentILPWithBlueprints(
        student: StudentAssessmentData,
        performanceAnalysis: PerformanceAnalysis,
        correlationModel: ValidatedCorrelationModel,
        progressionPlan: StudentProgressionPlan?
    ) async throws -> IndividualLearningPlan {
        
        // Use progression plan if available
        if let plan = progressionPlan {
            return await generateILPFromProgressionPlan(
                student: student,
                performanceAnalysis: performanceAnalysis,
                progressionPlan: plan,
                type: TimelineType.enrichment
            )
        }
        
        // Generate advanced objectives from next grade blueprints
        let nextGrade = min(student.grade + 1, 12)
        let advancedStandardIds = await getNextGradeStandards(
            currentGrade: student.grade,
            nextGrade: nextGrade,
            subject: student.assessments.first?.subject ?? "MATH"
        )
        
        // Convert to TargetStandard format
        let advancedStandards = advancedStandardIds.enumerated().map { index, standardId in
            TargetStandard(
                standardId: standardId,
                priority: index + 1,
                rationale: "Advanced/enrichment standard for high-achieving student"
            )
        }
        
        let enrichmentObjectives = await generateEnrichmentObjectives(
            standards: advancedStandards,
            studentLevel: performanceAnalysis.proficiencyLevel
        )
        
        return IndividualLearningPlan(
            studentInfo: createStudentInfo(from: student),
            assessmentDate: Date(),
            performanceSummary: performanceAnalysis,
            identifiedGaps: [],
            targetStandards: advancedStandards,
            learningObjectives: enrichmentObjectives,
            interventionStrategies: createEnrichmentStrategies(
                objectives: enrichmentObjectives,
                strengthAreas: performanceAnalysis.strengthAreas
            ),
            additionalRecommendations: [],
            predictedOutcomes: [],
            timeline: generateTimeline(
                startDate: Date(),
                objectives: enrichmentObjectives,
                type: TimelineType.enrichment
            )
        )
    }
    
    /// Generate ILP from progression plan
    func generateILPFromProgressionPlan(
        student: StudentAssessmentData,
        performanceAnalysis: PerformanceAnalysis,
        progressionPlan: StudentProgressionPlan,
        type: TimelineType
    ) async -> IndividualLearningPlan {
        
        // Convert progression plan focuses to learning objectives
        var learningObjectives: [ScaffoldedLearningObjective] = []
        
        for focus in progressionPlan.learningFocuses {
            // Get standard details
            if let standard = blueprintManager.getStandard(
                standardId: focus.standardId,
                grade: progressionPlan.currentGrade,
                subject: student.assessments.first?.subject ?? "MATH"
            ) {
                let objective = ScaffoldedLearningObjective(
                    standardId: focus.standardId,
                    standardDescription: standard.standard.description,
                    currentLevel: performanceAnalysis.proficiencyLevel,
                    targetLevel: determinTargetProficiency(
                        current: performanceAnalysis.proficiencyLevel,
                        focusArea: focus.focusArea
                    ),
                    knowledgeObjectives: createKnowledgeTasks(from: standard),
                    understandingObjectives: createUnderstandingTasks(from: standard),
                    skillsObjectives: createSkillsTasks(from: standard),
                    keywords: standard.relatedKeywords.terms,
                    successCriteria: generateSuccessCriteria(performanceAnalysis.proficiencyLevel),
                    estimatedTimeframe: focus.estimatedTimeWeeks
                )
                learningObjectives.append(objective)
            }
        }
        
        // Convert weak areas for ILP
        let identifiedGaps = progressionPlan.weakAreas.map { weakArea in
            WeakArea(
                component: weakArea.component,
                score: weakArea.performanceLevel.threshold * 100,
                gap: (1.0 - weakArea.performanceLevel.threshold) * 100,
                description: "Weakness in \(weakArea.component): \(weakArea.severity) severity"
            )
        }
        
        // Create intervention strategies based on action plan
        let interventions = progressionPlan.actionPlan.phases.map { phase in
            InterventionStrategy(
                tier: mapPhaseToInterventionTier(phase.name),
                frequency: determineFrequency(from: phase.timeframe),
                duration: phase.timeframe,
                groupSize: "Small group (3-5 students)",
                focus: phase.focuses.map { $0.standardId },
                instructionalApproach: generateInstructionalApproach(phase.name),
                materials: extractMaterials(from: phase.focuses),
                progressMonitoring: "Weekly progress checks with phase-end assessment"
            )
        }
        
        return IndividualLearningPlan(
            studentInfo: createStudentInfo(from: student),
            assessmentDate: Date(),
            performanceSummary: performanceAnalysis,
            identifiedGaps: identifiedGaps,
            targetStandards: progressionPlan.actionPlan.priorityStandards.enumerated().map { index, standardId in
                TargetStandard(
                    standardId: standardId,
                    priority: index + 1,
                    rationale: "Priority standard from progression plan"
                )
            },
            learningObjectives: learningObjectives,
            interventionStrategies: interventions,
            additionalRecommendations: [],
            predictedOutcomes: mapFutureImpacts(progressionPlan.futureImpacts),
            timeline: Timeline(
                startDate: Date(),
                endDate: Calendar.current.date(
                    byAdding: .weekOfYear,
                    value: progressionPlan.actionPlan.totalEstimatedWeeks,
                    to: Date()
                ) ?? Date(),
                milestones: generateMilestones(from: progressionPlan.actionPlan)
            )
        )
    }
    
    // MARK: - Blueprint Helper Methods
    
    /// Map weak areas to standards using blueprints
    func mapWeakAreasToStandardsWithBlueprints(
        _ weakAreas: [WeakArea],
        grade: Int,
        subject: String
    ) async -> [String] {
        var standards: Set<String> = []
        
        guard let blueprint = blueprintManager.getBlueprint(grade: grade, subject: subject) else {
            // Fallback to original method
            return await mapWeakAreasToStandards(weakAreas, grade: grade).map { $0.standardId }
        }
        
        for weakArea in weakAreas {
            // Extract component from weak area (format: "MATH_D1OP")
            let parts = weakArea.component.split(separator: "_")
            if parts.count >= 2 {
                let component = String(parts[1])
                
                // Find matching reporting category
                if let category = blueprintManager.getReportingCategory(
                    for: component,
                    grade: grade,
                    subject: subject
                ) {
                    // Add all standards from this category
                    for standardRef in category.standards {
                        standards.formUnion(standardRef.fullStandardCodes)
                    }
                }
            }
        }
        
        return Array(standards).sorted()
    }
    
    /// Generate objectives based on blueprint expectations
    func generateBlueprintBasedObjectives(
        standards: [String],
        studentLevel: ProficiencyLevel,
        grade: Int
    ) async -> [ScaffoldedLearningObjective] {
        var objectives: [ScaffoldedLearningObjective] = []
        
        for standardId in standards {
            // Extract subject from standard ID (e.g., "3.OA.1" -> Math)
            let subject = standardId.contains("RL") || standardId.contains("RI") ? "ELA" : "Mathematics"
            
            if let standard = blueprintManager.getStandard(
                standardId: standardId,
                grade: grade,
                subject: subject
            ) {
                // Create objective based on student's current level
                let objective = ScaffoldedLearningObjective(
                    standardId: standardId,
                    standardDescription: standard.standard.description,
                    currentLevel: studentLevel,
                    targetLevel: nextProficiencyLevel(from: studentLevel),
                    knowledgeObjectives: createKnowledgeTasks(from: standard),
                    understandingObjectives: createUnderstandingTasks(from: standard),
                    skillsObjectives: createSkillsTasks(from: standard),
                    keywords: standard.relatedKeywords.terms,
                    successCriteria: generateSuccessCriteria(studentLevel),
                    estimatedTimeframe: estimateTimeWeeks(for: studentLevel)
                )
                objectives.append(objective)
            }
        }
        
        return objectives
    }
    
    /// Get standards from next grade blueprint
    func getNextGradeStandards(
        currentGrade: Int,
        nextGrade: Int,
        subject: String
    ) async -> [String] {
        guard let blueprint = blueprintManager.getBlueprint(grade: nextGrade, subject: subject) else {
            return []
        }
        
        var standards: [String] = []
        
        // Get high-priority standards from next grade
        for category in blueprint.reportingCategories {
            if category.maxPercentage >= 25 {  // Focus on major categories
                for standardRef in category.standards {
                    standards.append(contentsOf: standardRef.fullStandardCodes)
                }
            }
        }
        
        return standards
    }
    
    // MARK: - Support Functions
    
    private func determineFocusArea(for level: ProficiencyLevel) -> FocusArea {
        switch level {
        case .minimal: return .knowledge
        case .basic: return .understanding
        case .passing: return .understanding
        case .proficient: return .skills
        case .advanced: return .enrichment
        }
    }
    
    private func generateActivities(for standard: LearningStandard, level: ProficiencyLevel) -> [String] {
        var activities: [String] = []
        
        switch level {
        case .minimal:
            activities = [
                "Use manipulatives and visual aids for \(standard.relatedKeywords.terms.first ?? "concepts")",
                "Complete guided practice with step-by-step support",
                "Review vocabulary: \(standard.relatedKeywords.terms.prefix(3).joined(separator: ", "))"
            ]
        case .basic:
            activities = [
                "Independent practice problems",
                "Apply concepts to word problems",
                "Collaborative group work"
            ]
        case .passing:
            activities = [
                "Solve grade-level problems independently",
                "Explain reasoning and show work",
                "Practice with mixed problem sets"
            ]
        case .proficient, .advanced:
            activities = [
                "Complex multi-step problems",
                "Real-world applications",
                "Create and solve original problems"
            ]
        }
        
        return activities
    }
    
    private func extractPrerequisites(from standard: LearningStandard) -> [String] {
        // Extract prerequisite concepts from knowledge items
        return Array(standard.studentPerformance.categories.knowledge.items.prefix(2))
    }
    
    private func generateAssessmentMethod(for standard: LearningStandard) -> String {
        let hasSkills = !standard.studentPerformance.categories.skills.items.isEmpty
        
        if hasSkills {
            return "Performance task demonstrating \(standard.studentPerformance.categories.skills.items.first ?? "skill application")"
        } else {
            return "Written assessment covering \(standard.standard.id) concepts"
        }
    }
    
    private func determinTargetProficiency(current: ProficiencyLevel, focusArea: FocusArea) -> ProficiencyLevel {
        switch focusArea {
        case .knowledge, .understanding:
            return .basic
        case .skills, .practice:
            return .proficient
        case .enrichment:
            return .advanced
        }
    }
    
    private func mapPhaseToInterventionTier(_ phaseName: String) -> InterventionStrategy.InterventionTier {
        if phaseName.contains("Immediate") {
            return .intensive
        } else if phaseName.contains("Short-term") {
            return .strategic
        } else {
            return .universal
        }
    }
    
    private func determineFrequency(from timeframe: String) -> String {
        if timeframe.contains("week") {
            return "Daily"
        } else if timeframe.contains("month") {
            return "3x per week"
        } else {
            return "Weekly"
        }
    }
    
    private func extractMaterials(from focuses: [LearningFocus]) -> [String] {
        var materials: Set<String> = []
        
        for focus in focuses {
            // Add materials based on focus area
            switch focus.focusArea {
            case .knowledge:
                materials.insert("Flashcards and vocabulary resources")
                materials.insert("Video tutorials")
            case .understanding:
                materials.insert("Concept maps and graphic organizers")
                materials.insert("Interactive demonstrations")
            case .skills:
                materials.insert("Practice worksheets")
                materials.insert("Online practice platforms")
            case .practice:
                materials.insert("Challenge problem sets")
                materials.insert("Assessment prep materials")
            case .enrichment:
                materials.insert("Advanced problem sets")
                materials.insert("Project-based learning resources")
            }
        }
        
        return Array(materials)
    }
    
    private func generateRecommendations(from plan: StudentProgressionPlan) -> [String] {
        var recommendations: [String] = []
        
        // Add recommendations based on weak areas
        if !plan.weakAreas.isEmpty {
            recommendations.append("Focus on \(plan.weakAreas.first?.reportingCategory ?? "identified") concepts before advancing")
        }
        
        // Add recommendations based on future impacts
        if plan.futureImpacts.count > 5 {
            recommendations.append("Address foundational gaps to prevent cascading difficulties in Grade \(plan.targetGrade)")
        }
        
        // Add time-based recommendations
        if plan.actionPlan.totalEstimatedWeeks > 20 {
            recommendations.append("Consider extended learning opportunities or summer programs")
        }
        
        return recommendations
    }
    
    private func mapFutureImpacts(_ impacts: [FutureImpact]) -> [PredictedRisk] {
        return impacts.prefix(5).map { impact in
            PredictedRisk(
                area: impact.targetComponent,
                riskLevel: "High",
                confidence: impact.confidence,
                recommendations: [impact.impactDescription]
            )
        }
    }
    
    private func generateMilestones(from actionPlan: ActionPlan) -> [Timeline.Milestone] {
        return actionPlan.phases.enumerated().map { index, phase in
            Timeline.Milestone(
                date: Calendar.current.date(
                    byAdding: .month,
                    value: index + 1,
                    to: Date()
                ) ?? Date(),
                description: "Complete \(phase.name)",
                assessmentType: index == actionPlan.phases.count - 1 ? "Summative" : "Formative"
            )
        }
    }
    
    private func generateAssessmentDates(weeks: Int) -> [Date] {
        var dates: [Date] = []
        let assessmentInterval = max(4, weeks / 4)  // Assess every 4 weeks or quarterly
        
        for week in stride(from: assessmentInterval, through: weeks, by: assessmentInterval) {
            if let date = Calendar.current.date(byAdding: .weekOfYear, value: week, to: Date()) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    private func estimateTime(for level: ProficiencyLevel) -> String {
        switch level {
        case .minimal: return "8-12 weeks"
        case .basic: return "6-8 weeks"
        case .passing: return "4-6 weeks"
        case .proficient: return "2-4 weeks"
        case .advanced: return "1-2 weeks"
        }
    }
    
    private func estimateTimeWeeks(for level: ProficiencyLevel) -> Int {
        switch level {
        case .minimal: return 10
        case .basic: return 7
        case .passing: return 5
        case .proficient: return 3
        case .advanced: return 2
        }
    }
    
    private func generateInstructionalApproach(_ phaseName: String) -> [String] {
        if phaseName.contains("Immediate") {
            return [
                "Direct instruction",
                "Explicit modeling",
                "Guided practice",
                "Immediate feedback"
            ]
        } else if phaseName.contains("Short-term") {
            return [
                "Small group instruction",
                "Scaffolded practice",
                "Peer collaboration",
                "Regular assessment"
            ]
        } else {
            return [
                "Differentiated instruction",
                "Independent practice",
                "Project-based learning",
                "Formative assessments"
            ]
        }
    }
    
    private func createKnowledgeTasks(from standard: LearningStandard) -> [LearningTask] {
        return standard.studentPerformance.categories.knowledge.items.prefix(3).map { item in
            LearningTask(
                description: item,
                complexity: .foundational,
                estimatedSessions: 2,
                assessmentType: "Quick check",
                resources: ["Flashcards", "Video tutorials"]
            )
        }
    }
    
    private func createUnderstandingTasks(from standard: LearningStandard) -> [LearningTask] {
        return standard.studentPerformance.categories.understanding.items.prefix(3).map { item in
            LearningTask(
                description: item,
                complexity: .intermediate,
                estimatedSessions: 3,
                assessmentType: "Concept application",
                resources: ["Practice problems", "Discussion prompts"]
            )
        }
    }
    
    private func createSkillsTasks(from standard: LearningStandard) -> [LearningTask] {
        return standard.studentPerformance.categories.skills.items.prefix(3).map { item in
            LearningTask(
                description: item,
                complexity: .advanced,
                estimatedSessions: 4,
                assessmentType: "Performance task",
                resources: ["Hands-on activities", "Real-world projects"]
            )
        }
    }
    
    private func generateSuccessCriteria(_ level: ProficiencyLevel) -> [String] {
        switch level {
        case .minimal:
            return [
                "Can identify basic concepts with support",
                "Completes tasks with guidance",
                "Demonstrates understanding through concrete examples"
            ]
        case .basic:
            return [
                "Can apply concepts in familiar contexts",
                "Works independently on routine tasks",
                "Shows understanding through explanations"
            ]
        case .passing:
            return [
                "Can solve grade-level problems",
                "Applies strategies appropriately",
                "Demonstrates conceptual understanding"
            ]
        case .proficient:
            return [
                "Can solve complex problems",
                "Makes connections across concepts",
                "Explains reasoning clearly"
            ]
        case .advanced:
            return [
                "Can solve challenging problems",
                "Creates novel solutions",
                "Teaches others effectively"
            ]
        }
    }
    
    private func nextProficiencyLevel(from current: ProficiencyLevel) -> ProficiencyLevel {
        switch current {
        case .minimal: return .basic
        case .basic: return .passing
        case .passing: return .proficient
        case .proficient: return .advanced
        case .advanced: return .advanced
        }
    }
}