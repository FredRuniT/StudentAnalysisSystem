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

public actor ILPGenerator {
    private let standardsRepository: StandardsRepository
    private let correlationEngine: CorrelationAnalyzer
    private let warningSystem: EarlyWarningSystem
    private let configuration: SystemConfiguration
    internal let blueprintManager: BlueprintManager
    private let progressionAnalyzer: GradeProgressionAnalyzer?
    
    public init(
        standardsRepository: StandardsRepository,
        correlationEngine: CorrelationAnalyzer,
        warningSystem: EarlyWarningSystem,
        configuration: SystemConfiguration? = nil,
        blueprintManager: BlueprintManager? = nil,
        componentCorrelationEngine: ComponentCorrelationEngine? = nil
    ) {
        self.standardsRepository = standardsRepository
        self.correlationEngine = correlationEngine
        self.warningSystem = warningSystem
        self.configuration = configuration ?? SystemConfiguration.default
        self.blueprintManager = blueprintManager ?? BlueprintManager.shared
        
        // Initialize progression analyzer if we have correlation engine
        if let componentEngine = componentCorrelationEngine {
            self.progressionAnalyzer = GradeProgressionAnalyzer(
                blueprintManager: self.blueprintManager,
                correlationEngine: componentEngine
            )
        } else {
            self.progressionAnalyzer = nil
        }
    }
    
    // MARK: - Main ILP Generation Methods
    
    /// Generate enhanced ILP with blueprint integration and grade progression
    public func generateEnhancedILP(
        student: StudentAssessmentData,
        correlationData: [ComponentCorrelationMap]? = nil,
        longitudinalData: StudentLongitudinalData? = nil,
        targetGrade: Int? = nil
    ) async throws -> IndividualLearningPlan {
        
        // Load blueprints and standards if not already loaded
        try await loadBlueprintData()
        
        // Analyze current performance
        let performanceAnalysis = await analyzeStudentPerformance(student)
        
        // Generate grade progression plan if we have longitudinal data and progression analyzer
        var progressionPlan: StudentProgressionPlan? = nil
        if let longitudinalData = longitudinalData,
           let analyzer = progressionAnalyzer {
            let target = targetGrade ?? (student.grade + 1)
            progressionPlan = analyzer.generateProgressionPlan(
                student: longitudinalData,
                currentGrade: student.grade,
                targetGrade: target
            )
        }
        
        // Determine ILP type based on performance
        // Create validated correlation model for ILP generation
        let emptyCorrelationMap = ComponentCorrelationMap(
            sourceComponent: ComponentIdentifier(grade: student.grade, subject: "MATH", component: "TEMP", testProvider: .nwea), 
            correlations: []
        )
        
        let fallbackValidationResults = ValidationResults(
            accuracy: 0.0,
            precision: 0.0,
            recall: 0.0,
            f1Score: 0.0,
            confusionMatrix: ValidationResults.ConfusionMatrix(
                truePositives: 0,
                trueNegatives: 0,
                falsePositives: 0,
                falseNegatives: 0
            )
        )
        
        let emptyValidatedModel = ValidatedCorrelationModel(
            correlations: [emptyCorrelationMap],
            validationResults: fallbackValidationResults,
            confidenceThreshold: 0.7,
            trainedDate: Date()
        )
        
        if performanceAnalysis.proficiencyLevel == .advanced || 
           performanceAnalysis.overallScore >= configuration.ilp.enrichmentThreshold {
            // Fallback to regular enrichment ILP
            return try await generateEnrichmentILP(student: student, performanceAnalysis: performanceAnalysis, correlationModel: emptyValidatedModel)
        } else {
            // Fallback to regular remediation ILP  
            return try await generateRemediationILP(student: student, performanceAnalysis: performanceAnalysis, correlationModel: emptyValidatedModel)
        }
    }
    
    /// Load blueprint and standards data
    private func loadBlueprintData() async throws {
        // Load blueprints if not already loaded
        if blueprintManager.getBlueprint(grade: 3, subject: "MATH") == nil {
            try blueprintManager.loadAllBlueprints()
            try blueprintManager.loadAllStandards()
        }
    }
    
    /// Generate ILP for any student - automatically detects if they need remediation or enrichment
    public func generateILP(
        student: StudentAssessmentData,
        correlationModel: ValidatedCorrelationModel,
        historicalData: [StudentLongitudinalData]? = nil
    ) async throws -> IndividualLearningPlan {
        
        // Analyze current performance
        let performanceAnalysis = await analyzeStudentPerformance(student)
        
        // Determine if student needs remediation or enrichment
        if performanceAnalysis.proficiencyLevel == .advanced || 
           performanceAnalysis.overallScore >= configuration.ilp.enrichmentThreshold {
            // Generate enrichment plan for excelling students
            return try await generateEnrichmentILP(
                student: student,
                performanceAnalysis: performanceAnalysis,
                correlationModel: correlationModel
            )
        } else {
            // Generate remediation plan for struggling students
            return try await generateRemediationILP(
                student: student,
                performanceAnalysis: performanceAnalysis,
                correlationModel: correlationModel
            )
        }
    }
    
    /// Generate remediation ILP for struggling students
    private func generateRemediationILP(
        student: StudentAssessmentData,
        performanceAnalysis: PerformanceAnalysis,
        correlationModel: ValidatedCorrelationModel
    ) async throws -> IndividualLearningPlan {
        
        // Identify weak areas
        let weakAreas = identifyWeakAreas(performanceAnalysis)
        
        // Map to standards
        let targetStandards = await mapWeakAreasToStandards(weakAreas, grade: student.grade)
        
        // Predict future risks
        let predictedRisks = await predictFutureRisks(
            performanceAnalysis,
            correlationModel
        )
        
        // Generate scaffolded objectives
        let learningObjectives = await generateScaffoldedObjectives(
            standards: targetStandards,
            studentLevel: performanceAnalysis.proficiencyLevel
        )
        
        // Create intervention strategies
        let interventions = createRemediationStrategies(
            objectives: learningObjectives,
            risks: predictedRisks
        )
        
        // Add prerequisite standards
        let bonusStandards = await recommendPrerequisiteStandards(
            weakAreas: weakAreas,
            grade: student.grade
        )
        
        return IndividualLearningPlan(
            studentInfo: createStudentInfo(from: student),
            assessmentDate: Date(),
            performanceSummary: performanceAnalysis,
            identifiedGaps: weakAreas,
            targetStandards: targetStandards,
            learningObjectives: learningObjectives,
            interventionStrategies: interventions,
            additionalRecommendations: bonusStandards,
            predictedOutcomes: predictedRisks,
            timeline: generateTimeline(
                startDate: Date(),
                objectives: learningObjectives,
                type: .remediation
            )
        )
    }
    
    /// Generate enrichment ILP for excelling/mastery students
    private func generateEnrichmentILP(
        student: StudentAssessmentData,
        performanceAnalysis: PerformanceAnalysis,
        correlationModel: ValidatedCorrelationModel
    ) async throws -> IndividualLearningPlan {
        
        // Identify strength areas for acceleration
        let strengthAreas = identifyStrengthAreas(performanceAnalysis)
        
        // Map to advanced/next-grade standards
        let targetStandards = await mapStrengthsToAdvancedStandards(
            strengthAreas,
            currentGrade: student.grade
        )
        
        // Predict areas of future excellence
        let predictedExcellence = await predictFutureExcellence(
            performanceAnalysis,
            correlationModel
        )
        
        // Generate enrichment objectives
        let learningObjectives = await generateEnrichmentObjectives(
            standards: targetStandards,
            studentLevel: performanceAnalysis.proficiencyLevel
        )
        
        // Create acceleration strategies
        let interventions = createAccelerationStrategies(
            objectives: learningObjectives,
            predictions: predictedExcellence
        )
        
        // Add cross-curricular and advanced standards
        let bonusStandards = await recommendEnrichmentStandards(
            strengthAreas: strengthAreas,
            correlationModel: correlationModel,
            grade: student.grade
        )
        
        return IndividualLearningPlan(
            studentInfo: createStudentInfo(from: student),
            assessmentDate: Date(),
            performanceSummary: performanceAnalysis,
            identifiedGaps: [], // No gaps for excelling students
            targetStandards: targetStandards,
            learningObjectives: learningObjectives,
            interventionStrategies: interventions,
            additionalRecommendations: bonusStandards,
            predictedOutcomes: predictedExcellence,
            timeline: generateTimeline(
                startDate: Date(),
                objectives: learningObjectives,
                type: .enrichment
            )
        )
    }
    
    // MARK: - Performance Analysis
    
    private func analyzeStudentPerformance(
        _ student: StudentAssessmentData
    ) async -> PerformanceAnalysis {
        
        // Calculate overall score and determine proficiency
        let overallScore = student.assessments.map { $0.overallScore }.reduce(0, +) / Double(student.assessments.count)
        
        // Use actual proficiency level from data if available, otherwise determine from score
        let proficiencyLevel: ProficiencyLevel
        if let firstProfLevel = student.assessments.first?.proficiencyLevel {
            proficiencyLevel = mapProficiencyLevel(firstProfLevel)
        } else {
            proficiencyLevel = determineProficiencyLevelFromScale(score: overallScore)
        }
        
        // Analyze component scores
        var componentScores = [String: Double]()
        var strengthAreas = [String]()
        var weakAreas = [String]()
        
        for assessment in student.assessments {
            for (component, score) in assessment.componentScores {
                let key = "\(assessment.subject)_\(component)"
                componentScores[key] = score
                
                if score >= 70 {
                    strengthAreas.append(key)
                } else if score < 50 {
                    weakAreas.append(key)
                }
            }
        }
        
        return PerformanceAnalysis(
            overallScore: overallScore,
            proficiencyLevel: proficiencyLevel,
            componentScores: componentScores,
            strengthAreas: strengthAreas,
            weakAreas: weakAreas
        )
    }
    
    // MARK: - Gap and Strength Identification
    
    internal func identifyWeakAreas(_ analysis: PerformanceAnalysis) -> [WeakArea] {
        var weakAreas = [WeakArea]()
        
        for area in analysis.weakAreas {
            let score = analysis.componentScores[area] ?? 0
            let gap = 70 - score // Gap from proficiency
            
            weakAreas.append(
                WeakArea(
                    component: area,
                    score: score,
                    gap: gap,
                    description: "Performance gap in \(area): \(String(format: "%.1f", gap)) points below proficiency"
                )
            )
        }
        
        return weakAreas.sorted { $0.gap > $1.gap }
    }
    
    private func identifyStrengthAreas(_ analysis: PerformanceAnalysis) -> [StrengthArea] {
        var strengthAreas = [StrengthArea]()
        
        for area in analysis.strengthAreas {
            let score = analysis.componentScores[area] ?? 0
            
            strengthAreas.append(
                StrengthArea(
                    component: area,
                    score: score,
                    percentile: calculatePercentile(score),
                    readyForAcceleration: score >= 85
                )
            )
        }
        
        return strengthAreas.sorted { $0.score > $1.score }
    }
    
    // MARK: - Standards Mapping
    
    internal func mapWeakAreasToStandards(_ weakAreas: [WeakArea], grade: Int) async -> [TargetStandard] {
        var targetStandards = [TargetStandard]()
        
        for area in weakAreas {
            let standards = await standardsRepository.getStandardsForComponent(
                component: extractComponentName(from: area.component),
                grade: String(grade),
                subject: extractSubject(from: area.component)
            )
            
            for (index, standard) in standards.prefix(3).enumerated() {
                targetStandards.append(
                    TargetStandard(
                        standardId: standard.standard.id,
                        priority: weakAreas.firstIndex(of: area)! * 10 + index + 1,
                        rationale: "Addresses gap in \(area.component)"
                    )
                )
            }
        }
        
        return targetStandards
    }
    
    private func mapStrengthsToAdvancedStandards(
        _ strengthAreas: [StrengthArea],
        currentGrade: Int
    ) async -> [TargetStandard] {
        var targetStandards = [TargetStandard]()
        let nextGrade = currentGrade + 1
        
        for area in strengthAreas where area.readyForAcceleration {
            // Get next grade standards
            let standards = await standardsRepository.getStandardsForComponent(
                component: extractComponentName(from: area.component),
                grade: String(nextGrade),
                subject: extractSubject(from: area.component)
            )
            
            for (index, standard) in standards.prefix(2).enumerated() {
                targetStandards.append(
                    TargetStandard(
                        standardId: standard.standard.id,
                        priority: index + 1,
                        rationale: "Grade \(nextGrade) acceleration in area of strength"
                    )
                )
            }
        }
        
        return targetStandards
    }
    
    // MARK: - Risk and Excellence Prediction
    
    private func predictFutureRisks(
        _ performance: PerformanceAnalysis,
        _ model: ValidatedCorrelationModel
    ) async -> [PredictedRisk] {
        var risks = [PredictedRisk]()
        
        for weakArea in performance.weakAreas {
            // Find correlations showing future impact
            let correlatedAreas = findCorrelatedAreas(
                component: weakArea,
                in: model.correlations
            )
            
            for correlation in correlatedAreas {
                let riskLevel: String
                if correlation.confidence > 0.7 && performance.componentScores[weakArea]! < 40 {
                    riskLevel = "High"
                } else if correlation.confidence > 0.5 {
                    riskLevel = "Moderate"
                } else {
                    riskLevel = "Low"
                }
                
                risks.append(
                    PredictedRisk(
                        area: correlation.targetComponent,
                        riskLevel: riskLevel,
                        confidence: correlation.confidence,
                        recommendations: generateRiskMitigationRecommendations(
                            area: correlation.targetComponent,
                            level: riskLevel
                        )
                    )
                )
            }
        }
        
        return risks
    }
    
    private func predictFutureExcellence(
        _ performance: PerformanceAnalysis,
        _ model: ValidatedCorrelationModel
    ) async -> [PredictedRisk] {
        var predictions = [PredictedRisk]()
        
        for strengthArea in performance.strengthAreas {
            let correlatedAreas = findCorrelatedAreas(
                component: strengthArea,
                in: model.correlations
            )
            
            for correlation in correlatedAreas where correlation.confidence > 0.6 {
                predictions.append(
                    PredictedRisk(
                        area: correlation.targetComponent,
                        riskLevel: "Excellence Expected",
                        confidence: correlation.confidence,
                        recommendations: [
                            "Continue advanced work in \(correlation.targetComponent)",
                            "Consider competition preparation",
                            "Explore research opportunities"
                        ]
                    )
                )
            }
        }
        
        return predictions
    }
    
    // MARK: - Learning Objectives Generation
    
    private func generateScaffoldedObjectives(
        standards: [TargetStandard],
        studentLevel: ProficiencyLevel
    ) async -> [ScaffoldedLearningObjective] {
        var objectives = [ScaffoldedLearningObjective]()
        
        for standard in standards {
            let scaffolded = await standardsRepository.getScaffoldedStandard(
                standardId: standard.standardId
            )
            
            guard let scaffolded = scaffolded else { continue }
            
            objectives.append(
                ScaffoldedLearningObjective(
                    standardId: standard.standardId,
                    standardDescription: scaffolded.standard.description,
                    currentLevel: studentLevel,
                    targetLevel: .proficient,
                    knowledgeObjectives: createKnowledgeTasks(from: scaffolded),
                    understandingObjectives: createUnderstandingTasks(from: scaffolded),
                    skillsObjectives: createSkillsTasks(from: scaffolded),
                    keywords: scaffolded.relatedKeywords?.terms ?? [],
                    successCriteria: generateSuccessCriteria(studentLevel),
                    estimatedTimeframe: calculateTimeframe(studentLevel)
                )
            )
        }
        
        return objectives
    }
    
    internal func generateEnrichmentObjectives(
        standards: [TargetStandard],
        studentLevel: ProficiencyLevel
    ) async -> [ScaffoldedLearningObjective] {
        var objectives = [ScaffoldedLearningObjective]()
        
        for standard in standards {
            let scaffolded = await standardsRepository.getScaffoldedStandard(
                standardId: standard.standardId
            )
            
            guard let scaffolded = scaffolded else { continue }
            
            objectives.append(
                ScaffoldedLearningObjective(
                    standardId: standard.standardId,
                    standardDescription: scaffolded.standard.description,
                    currentLevel: studentLevel,
                    targetLevel: .advanced,
                    knowledgeObjectives: createAdvancedKnowledgeTasks(from: scaffolded),
                    understandingObjectives: createAdvancedUnderstandingTasks(from: scaffolded),
                    skillsObjectives: createAdvancedSkillsTasks(from: scaffolded),
                    keywords: scaffolded.relatedKeywords?.terms ?? [],
                    successCriteria: generateAdvancedSuccessCriteria(),
                    estimatedTimeframe: 6 // Shorter for advanced students
                )
            )
        }
        
        return objectives
    }
    
    // MARK: - Intervention Strategies
    
    internal func createRemediationStrategies(
        objectives: [ScaffoldedLearningObjective],
        risks: [PredictedRisk]
    ) -> [InterventionStrategy] {
        var strategies = [InterventionStrategy]()
        
        let highRiskCount = risks.filter { $0.riskLevel == "High" }.count
        
        if highRiskCount > 2 {
            // Intensive intervention needed
            strategies.append(
                InterventionStrategy(
                    tier: .intensive,
                    frequency: "Daily",
                    duration: "45 minutes",
                    groupSize: "1-2 students",
                    focus: objectives.map { $0.standardId },
                    instructionalApproach: [
                        "Explicit, systematic instruction",
                        "Immediate corrective feedback",
                        "Multiple practice opportunities",
                        "Visual and manipulative supports"
                    ],
                    materials: generateRemediationMaterials(objectives),
                    progressMonitoring: "Daily progress checks with weekly assessments"
                )
            )
        } else {
            // Strategic intervention
            strategies.append(
                InterventionStrategy(
                    tier: .strategic,
                    frequency: "3x per week",
                    duration: "30 minutes",
                    groupSize: "3-5 students",
                    focus: objectives.map { $0.standardId },
                    instructionalApproach: [
                        "Targeted skill instruction",
                        "Guided practice",
                        "Peer collaboration",
                        "Regular feedback"
                    ],
                    materials: generateStrategicMaterials(objectives),
                    progressMonitoring: "Weekly progress monitoring"
                )
            )
        }
        
        return strategies
    }
    
    private func createAccelerationStrategies(
        objectives: [ScaffoldedLearningObjective],
        predictions: [PredictedRisk]
    ) -> [InterventionStrategy] {
        return [
            InterventionStrategy(
                tier: .universal, // Enrichment within regular class
                frequency: "Daily with extended projects",
                duration: "Variable - self-paced",
                groupSize: "Individual or small group",
                focus: objectives.map { $0.standardId },
                instructionalApproach: [
                    "Project-based learning",
                    "Independent research",
                    "Peer teaching opportunities",
                    "Real-world applications",
                    "Competition preparation"
                ],
                materials: generateEnrichmentMaterials(objectives),
                progressMonitoring: "Portfolio assessment and project rubrics"
            )
        ]
    }
    
    internal func createEnrichmentStrategies(
        objectives: [ScaffoldedLearningObjective],
        strengthAreas: [String]
    ) -> [InterventionStrategy] {
        return [
            InterventionStrategy(
                tier: .universal, // Enrichment within regular class
                frequency: "Daily with advanced activities",
                duration: "Variable - self-paced",
                groupSize: "Individual or collaborative groups",
                focus: objectives.map { $0.standardId },
                instructionalApproach: [
                    "Advanced problem-solving",
                    "Creative projects",
                    "Cross-curricular connections",
                    "Leadership opportunities",
                    "Research and exploration"
                ],
                materials: generateEnrichmentMaterials(objectives),
                progressMonitoring: "Project-based assessment and portfolio review"
            )
        ]
    }
    
    // MARK: - Bonus Standards
    
    private func recommendPrerequisiteStandards(
        weakAreas: [WeakArea],
        grade: Int
    ) async -> [BonusStandard] {
        var bonusStandards = [BonusStandard]()
        
        for area in weakAreas.prefix(3) {
            let prerequisites = await standardsRepository.getPrerequisiteStandards(
                for: extractComponentName(from: area.component),
                grade: String(grade)
            )
            
            for prereq in prerequisites.prefix(2) {
                bonusStandards.append(
                    BonusStandard(
                        standard: prereq,
                        rationale: "Essential foundation for \(area.component)",
                        type: .prerequisite,
                        expectedBenefit: "Builds foundation for current grade-level work"
                    )
                )
            }
        }
        
        return bonusStandards
    }
    
    private func recommendEnrichmentStandards(
        strengthAreas: [StrengthArea],
        correlationModel: ValidatedCorrelationModel,
        grade: Int
    ) async -> [BonusStandard] {
        var bonusStandards = [BonusStandard]()
        
        for area in strengthAreas.prefix(3) {
            // Add cross-curricular connections
            let relatedStandards = await findCrossCurricularStandards(
                component: area.component,
                grade: grade
            )
            
            for standard in relatedStandards.prefix(2) {
                bonusStandards.append(
                    BonusStandard(
                        standard: standard,
                        rationale: "Cross-curricular extension of strength in \(area.component)",
                        type: .crossCurricular,
                        expectedBenefit: "Develops interdisciplinary thinking"
                    )
                )
            }
        }
        
        return bonusStandards
    }
    
    // MARK: - Timeline Generation
    
    internal func generateTimeline(
        startDate: Date,
        objectives: [ScaffoldedLearningObjective],
        type: TimelineType
    ) -> Timeline {
        let calendar = Calendar.current
        var milestones = [Timeline.Milestone]()
        var currentDate = startDate
        
        // Initial assessment
        milestones.append(
            Timeline.Milestone(
                date: currentDate,
                description: "Initial assessment and ILP review",
                assessmentType: "Diagnostic"
            )
        )
        
        // Add milestones for each objective
        for objective in objectives {
            currentDate = calendar.date(
                byAdding: .weekOfYear,
                value: objective.estimatedTimeframe / 2,
                to: currentDate
            )!
            
            milestones.append(
                Timeline.Milestone(
                    date: currentDate,
                    description: "Mid-point check: \(objective.standardId)",
                    assessmentType: "Formative"
                )
            )
            
            currentDate = calendar.date(
                byAdding: .weekOfYear,
                value: objective.estimatedTimeframe / 2,
                to: currentDate
            )!
            
            milestones.append(
                Timeline.Milestone(
                    date: currentDate,
                    description: "Mastery assessment: \(objective.standardId)",
                    assessmentType: "Summative"
                )
            )
        }
        
        // Final assessment
        let endDate = calendar.date(
            byAdding: .weekOfMonth,
            value: 1,
            to: currentDate
        )!
        
        milestones.append(
            Timeline.Milestone(
                date: endDate,
                description: type == .enrichment ? 
                    "Portfolio presentation and advancement assessment" :
                    "Comprehensive progress assessment",
                assessmentType: "Summative"
            )
        )
        
        return Timeline(
            startDate: startDate,
            endDate: endDate,
            milestones: milestones
        )
    }
    
    // MARK: - Helper Functions
    
    internal func createStudentInfo(from student: StudentAssessmentData) -> IndividualLearningPlan.StudentInfo {
        return IndividualLearningPlan.StudentInfo(
            msis: student.studentInfo.msis,
            name: student.studentInfo.name,
            grade: student.grade,
            school: student.studentInfo.school,
            testDate: Date(),
            testType: student.assessments.first?.testProvider.rawValue ?? "Unknown"
        )
    }
    
    private func determineProficiencyLevel(score: Double) -> ProficiencyLevel {
        switch score {
        case 85...100: return .advanced
        case 70..<85: return .proficient
        case 50..<70: return .passing
        case 25..<50: return .basic
        default: return .minimal
        }
    }
    
    private func determineProficiencyLevelFromScale(score: Double) -> ProficiencyLevel {
        // For SCALE_SCORE (typically 100-850 range)
        // Mississippi MAAP typical cutoffs (approximate)
        switch score {
        case 650...850: return .advanced     // PL5
        case 550..<650: return .proficient   // PL4
        case 450..<550: return .passing      // PL3 (Passing)
        case 350..<450: return .basic        // PL2
        default: return .minimal              // PL1
        }
    }
    
    private func mapProficiencyLevel(_ profLevel: String) -> ProficiencyLevel {
        switch profLevel.uppercased() {
        case "PL5", "ADVANCED": return .advanced
        case "PL4", "PROFICIENT": return .proficient
        case "PL3", "PASSING": return .passing
        case "PL2", "BASIC": return .basic
        case "PL1", "MINIMAL", "BELOW BASIC": return .minimal
        default: return .minimal
        }
    }
    
    private func calculatePercentile(_ score: Double) -> Double {
        // Simplified percentile calculation - in production would use actual distribution
        return min(100, max(0, (score - 30) * 1.43))
    }
    
    private func extractComponentName(from componentKey: String) -> String {
        return componentKey.components(separatedBy: "_").last ?? componentKey
    }
    
    private func extractSubject(from componentKey: String) -> String {
        return componentKey.components(separatedBy: "_").first ?? "Unknown"
    }
    
    private func findCorrelatedAreas(
        component: String,
        in correlations: [ComponentCorrelationMap]
    ) -> [(targetComponent: String, confidence: Double)] {
        var results = [(String, Double)]()
        
        for map in correlations {
            if map.sourceComponent.description.contains(component) {
                for correlation in map.correlations {
                    results.append((
                        correlation.target.description,
                        correlation.confidence
                    ))
                }
            }
        }
        
        return results
    }
    
    private func generateRiskMitigationRecommendations(area: String, level: String) -> [String] {
        switch level {
        case "High":
            return [
                "Immediate intensive intervention required",
                "Daily progress monitoring",
                "Parent communication and support plan",
                "Consider assessment for learning disabilities"
            ]
        case "Moderate":
            return [
                "Strategic intervention recommended",
                "Weekly progress monitoring",
                "Small group instruction",
                "Additional practice opportunities"
            ]
        default:
            return [
                "Monitor progress regularly",
                "Provide differentiated instruction",
                "Encourage practice at home"
            ]
        }
    }
    
    private func createKnowledgeTasks(from standard: ScaffoldedStandard) -> [LearningTask] {
        return standard.studentPerformance.categories.knowledge.items.map {
            LearningTask(
                description: $0,
                complexity: .foundational,
                estimatedSessions: 2,
                assessmentType: "Knowledge check",
                resources: ["Textbook", "Video lessons", "Flashcards"]
            )
        }
    }
    
    private func createUnderstandingTasks(from standard: ScaffoldedStandard) -> [LearningTask] {
        return standard.studentPerformance.categories.understanding.items.map {
            LearningTask(
                description: $0,
                complexity: .intermediate,
                estimatedSessions: 3,
                assessmentType: "Concept application",
                resources: ["Interactive activities", "Group discussions", "Concept maps"]
            )
        }
    }
    
    private func createSkillsTasks(from standard: ScaffoldedStandard) -> [LearningTask] {
        return standard.studentPerformance.categories.skills.items.map {
            LearningTask(
                description: $0,
                complexity: .advanced,
                estimatedSessions: 4,
                assessmentType: "Performance task",
                resources: ["Practice problems", "Real-world applications", "Projects"]
            )
        }
    }
    
    private func createAdvancedKnowledgeTasks(from standard: ScaffoldedStandard) -> [LearningTask] {
        return [
            LearningTask(
                description: "Research and present on advanced concepts",
                complexity: .advanced,
                estimatedSessions: 2,
                assessmentType: "Research presentation",
                resources: ["Academic journals", "Online databases", "Expert interviews"]
            )
        ]
    }
    
    private func createAdvancedUnderstandingTasks(from standard: ScaffoldedStandard) -> [LearningTask] {
        return [
            LearningTask(
                description: "Analyze complex relationships and patterns",
                complexity: .advanced,
                estimatedSessions: 3,
                assessmentType: "Critical analysis",
                resources: ["Case studies", "Data sets", "Simulation software"]
            )
        ]
    }
    
    private func createAdvancedSkillsTasks(from standard: ScaffoldedStandard) -> [LearningTask] {
        return [
            LearningTask(
                description: "Design and execute independent project",
                complexity: .advanced,
                estimatedSessions: 6,
                assessmentType: "Project portfolio",
                resources: ["Lab equipment", "Design software", "Mentorship"]
            )
        ]
    }
    
    private func generateSuccessCriteria(_ level: ProficiencyLevel) -> [String] {
        switch level {
        case .minimal:
            return [
                "Demonstrates understanding of basic concepts",
                "Completes guided practice with support",
                "Shows improvement from baseline"
            ]
        case .basic:
            return [
                "Applies concepts with minimal support",
                "Achieves 50% accuracy on assessments",
                "Completes independent practice"
            ]
        case .passing:
            return [
                "Masters grade-level standards",
                "Achieves 70% accuracy on assessments",
                "Applies knowledge to familiar situations"
            ]
        case .proficient:
            return [
                "Exceeds grade-level standards",
                "Applies knowledge to new situations",
                "Achieves 80% or higher on assessments"
            ]
        case .advanced:
            return generateAdvancedSuccessCriteria()
        }
    }
    
    private func generateAdvancedSuccessCriteria() -> [String] {
        return [
            "Exceeds grade-level expectations",
            "Demonstrates creative problem-solving",
            "Teaches concepts to peers",
            "Completes advanced projects independently",
            "Achieves 95% or higher on advanced assessments"
        ]
    }
    
    private func calculateTimeframe(_ level: ProficiencyLevel) -> Int {
        switch level {
        case .minimal: return 12 // weeks
        case .basic: return 10
        case .passing: return 8
        case .proficient: return 6
        case .advanced: return 4
        }
    }
    
    private func generateRemediationMaterials(_ objectives: [ScaffoldedLearningObjective]) -> [String] {
        return [
            "Intervention workbooks",
            "Manipulatives and visual aids",
            "Online practice platforms",
            "Differentiated worksheets",
            "Progress monitoring tools"
        ]
    }
    
    private func generateStrategicMaterials(_ objectives: [ScaffoldedLearningObjective]) -> [String] {
        return [
            "Targeted skill packets",
            "Small group activities",
            "Digital learning games",
            "Practice assessments",
            "Parent support materials"
        ]
    }
    
    private func generateEnrichmentMaterials(_ objectives: [ScaffoldedLearningObjective]) -> [String] {
        return [
            "Advanced textbooks",
            "Research resources",
            "Competition preparation materials",
            "Project supplies",
            "Mentorship connections",
            "University-level resources"
        ]
    }
    
    private func findCrossCurricularStandards(
        component: String,
        grade: Int
    ) async -> [ScaffoldedStandard] {
        // This would connect to other subject areas
        // For now, returning empty array
        return []
    }
    
    
    // MARK: - Supporting Types
    
    private struct StrengthArea: Equatable {
        let component: String
        let score: Double
        let percentile: Double
        let readyForAcceleration: Bool
    }
    
    public enum TimelineType: String, Sendable {
        case remediation
        case enrichment
    }
}

// Extension is no longer needed - StudentAssessmentData already has a grade property