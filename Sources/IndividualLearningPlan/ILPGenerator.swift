//
//  ILPGenerator.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//

import Foundation
import MLX
import AnalysisCore
import StatisticalEngine
import PredictiveModeling

public actor IndividualLearningPlanGenerator {
    private let standardsRepository: StandardsRepository
    private let correlationEngine: CorrelationAnalyzer
    private let warningSystem: EarlyWarningSystem
    
    public init(
        standardsRepository: StandardsRepository,
        correlationEngine: CorrelationAnalyzer,
        warningSystem: EarlyWarningSystem
    ) {
        self.standardsRepository = standardsRepository
        self.correlationEngine = correlationEngine
        self.warningSystem = warningSystem
    }
    
    public func generateILP(
        student: StudentAssessmentData,
        correlationModel: ValidatedCorrelationModel,
        historicalData: [StudentLongitudinalData]? = nil
    ) async throws -> IndividualLearningPlan {
        
        // 1. Analyze current performance
        let performanceAnalysis = await analyzeStudentPerformance(student)
        
        // 2. Identify weak reporting categories/domains
        let weakAreas = identifyWeakAreas(performanceAnalysis)
        
        // 3. Map weak areas to specific standards
        let targetStandards = await mapToStandards(weakAreas)
        
        // 4. Use correlation model to predict future risks
        let predictedRisks = await predictFutureRisks(
            currentPerformance: performanceAnalysis,
            model: correlationModel
        )
        
        // 5. Generate scaffolded learning objectives
        let learningObjectives = await generateScaffoldedObjectives(
            standards: targetStandards,
            studentLevel: performanceAnalysis
        )
        
        // 6. Create intervention strategies based on blueprint
        let interventions = await createInterventionStrategies(
            objectives: learningObjectives,
            risks: predictedRisks
        )
        
        // 7. Add bonus standards based on correlation discoveries
        let bonusStandards = await recommendAdditionalStandards(
            student: student,
            correlations: correlationModel
        )
        
        return IndividualLearningPlan(
            studentInfo: student.studentInfo,
            assessmentDate: Date(),
            performanceSummary: performanceAnalysis,
            identifiedGaps: weakAreas,
            targetStandards: targetStandards,
            learningObjectives: learningObjectives,
            interventionStrategies: interventions,
            additionalRecommendations: bonusStandards,
            predictedOutcomes: predictedRisks,
            timeline: generateTimeline(objectives: learningObjectives)
        )
    }
    
    private func analyzeStudentPerformance(
        _ student: StudentAssessmentData
    ) async -> PerformanceAnalysis {
        var analysis = PerformanceAnalysis()
        
        // Analyze each component score
        for (component, score) in student.componentScores {
            let proficiencyLevel = determineProficiencyLevel(score: score, component: component)
            let percentile = await calculatePercentile(score: score, component: component)
            
            analysis.components.append(
                ComponentAnalysis(
                    component: component,
                    score: score,
                    proficiencyLevel: proficiencyLevel,
                    percentile: percentile,
                    needsIntervention: proficiencyLevel < .proficient
                )
            )
        }
        
        // Calculate overall performance metrics
        analysis.overallProficiency = calculateOverallProficiency(analysis.components)
        analysis.strengths = identifyStrengths(analysis.components)
        analysis.weaknesses = identifyWeaknesses(analysis.components)
        
        return analysis
    }
    
    private func mapToStandards(_ weakAreas: [WeakArea]) async -> [TargetStandard] {
        var targetStandards: [TargetStandard] = []
        
        for area in weakAreas {
            // Get all standards that map to this reporting category/domain
            let standards = await standardsRepository.getStandardsForComponent(
                component: area.component,
                grade: area.grade,
                subject: area.subject
            )
            
            // Prioritize standards based on severity and importance
            let prioritized = prioritizeStandards(
                standards: standards,
                severity: area.severity
            )
            
            for standard in prioritized {
                targetStandards.append(
                    TargetStandard(
                        standard: standard,
                        priority: calculatePriority(area.severity, standard),
                        currentGap: area.gapFromProficient,
                        estimatedTimeToMaster: estimateMasteryTime(standard, area.severity)
                    )
                )
            }
        }
        
        return targetStandards.sorted { $0.priority > $1.priority }
    }
    
    private func generateScaffoldedObjectives(
        standards: [TargetStandard],
        studentLevel: PerformanceAnalysis
    ) async -> [ScaffoldedLearningObjective] {
        var objectives: [ScaffoldedLearningObjective] = []
        
        for targetStandard in standards {
            let scaffolded = await standardsRepository.getScaffoldedStandard(
                standardId: targetStandard.standard.id
            )
            
            guard let scaffolded = scaffolded else { continue }
            
            // Create progressive learning objectives
            let objective = ScaffoldedLearningObjective(
                standardId: scaffolded.standard.id,
                standardDescription: scaffolded.standard.description,
                currentLevel: studentLevel.overallProficiency,
                targetLevel: .proficient,
                
                // Phase 1: Build Knowledge
                knowledgeObjectives: scaffolded.studentPerformance.categories.knowledge.items.map {
                    LearningTask(
                        description: $0,
                        complexity: .foundational,
                        estimatedSessions: 2,
                        assessmentType: "Knowledge Check",
                        resources: getResourcesForKnowledge($0)
                    )
                },
                
                // Phase 2: Develop Understanding
                understandingObjectives: scaffolded.studentPerformance.categories.understanding.items.map {
                    LearningTask(
                        description: $0,
                        complexity: .intermediate,
                        estimatedSessions: 3,
                        assessmentType: "Concept Application",
                        resources: getResourcesForUnderstanding($0)
                    )
                },
                
                // Phase 3: Apply Skills
                skillsObjectives: scaffolded.studentPerformance.categories.skills.items.map {
                    LearningTask(
                        description: $0,
                        complexity: .advanced,
                        estimatedSessions: 4,
                        assessmentType: "Performance Task",
                        resources: getResourcesForSkills($0)
                    )
                },
                
                keywords: scaffolded.relatedKeywords?.terms ?? [],
                successCriteria: generateSuccessCriteria(scaffolded, studentLevel)
            )
            
            objectives.append(objective)
        }
        
        return objectives
    }
    
    private func createInterventionStrategies(
        objectives: [ScaffoldedLearningObjective],
        risks: [PredictedRisk]
    ) async -> [InterventionStrategy] {
        var strategies: [InterventionStrategy] = []
        
        // Group objectives by urgency based on risks
        let urgent = objectives.filter { obj in
            risks.contains { $0.relatedStandardId == obj.standardId && $0.riskLevel == .high }
        }
        
        let moderate = objectives.filter { obj in
            risks.contains { $0.relatedStandardId == obj.standardId && $0.riskLevel == .moderate }
        }
        
        // Create tiered intervention plan
        if !urgent.isEmpty {
            strategies.append(
                InterventionStrategy(
                    tier: .intensive,
                    frequency: "Daily",
                    duration: "30-45 minutes",
                    groupSize: "1-3 students",
                    focus: urgent.map(\.standardId),
                    instructionalApproach: [
                        "Explicit instruction with modeling",
                        "Guided practice with immediate feedback",
                        "Systematic error correction",
                        "Progress monitoring 2x weekly"
                    ],
                    materials: generateMaterialsList(for: urgent)
                )
            )
        }
        
        if !moderate.isEmpty {
            strategies.append(
                InterventionStrategy(
                    tier: .strategic,
                    frequency: "3x per week",
                    duration: "20-30 minutes",
                    groupSize: "4-6 students",
                    focus: moderate.map(\.standardId),
                    instructionalApproach: [
                        "Small group instruction",
                        "Differentiated activities",
                        "Peer collaboration",
                        "Weekly progress checks"
                    ],
                    materials: generateMaterialsList(for: moderate)
                )
            )
        }
        
        return strategies
    }
    
    private func recommendAdditionalStandards(
        student: StudentAssessmentData,
        correlations: ValidatedCorrelationModel
    ) async -> [BonusStandard] {
        var bonusStandards: [BonusStandard] = []
        
        // Find standards that correlate with future success
        let strongComponents = student.componentScores.filter { $0.value > 70 }
        
        for (component, score) in strongComponents {
            // Find what this strength predicts
            let predictions = correlations.getPositiveCorrelations(for: component)
            
            for prediction in predictions where prediction.correlation > 0.6 {
                // Get enrichment standards for this area
                let enrichmentStandards = await standardsRepository.getEnrichmentStandards(
                    baseComponent: component,
                    targetComponent: prediction.targetComponent,
                    grade: student.grade
                )
                
                for standard in enrichmentStandards {
                    bonusStandards.append(
                        BonusStandard(
                            standard: standard,
                            rationale: """
                            Student shows strength in \(component) (score: \(score)).
                            Historical data shows \(String(format: "%.0f%%", prediction.correlation * 100)) 
                            correlation with future success in \(prediction.targetComponent).
                            """,
                            type: .enrichment,
                            expectedBenefit: prediction.predictedImprovement
                        )
                    )
                }
            }
        }
        
        // Also add prerequisite standards for identified gaps
        let weakComponents = student.componentScores.filter { $0.value < 50 }
        
        for (component, _) in weakComponents {
            let prerequisites = await standardsRepository.getPrerequisiteStandards(
                for: component,
                grade: student.grade
            )
            
            for prereq in prerequisites {
                bonusStandards.append(
                    BonusStandard(
                        standard: prereq,
                        rationale: "Foundational skill needed for \(component)",
                        type: .prerequisite,
                        expectedBenefit: "Addresses root cause of current struggle"
                    )
                )
            }
        }
        
        return bonusStandards
    }
}
