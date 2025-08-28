import AnalysisCore
import Foundation
import IndividualLearningPlan

// MARK: - Model Adapters
// These adapters bridge the gap between backend models and UI models

// MARK: - IndividualLearningPlan Adapters
extension IndividualLearningPlan {
    /// Convert backend ILP to UI model
    public func toUIModel() -> UIIndividualLearningPlan {
        return UIIndividualLearningPlan(
            studentMSIS: studentInfo.msis,
            studentName: studentInfo.name,
            currentGrade: studentInfo.grade,
            targetGrade: studentInfo.grade + 1,
            createdDate: assessmentDate,
            targetCompletionDate: timeline.endDate,
            performanceSummary: [
                "Overall Score: \(performanceSummary.overallScore)",
                "Proficiency Level: \(performanceSummary.proficiencyLevel.rawValue)"
            ] + performanceSummary.strengthAreas.map { "Strength: \($0)" } +
              performanceSummary.weakAreas.map { "Needs Support: \($0)" },
            focusAreas: identifiedGaps.map { $0.toUIModel() },
            learningObjectives: learningObjectives.map { $0.toUIModel() },
            milestones: timeline.milestones.map { $0.toUIModel() },
            interventionStrategies: interventionStrategies.map { $0.toUIModel() },
            timeline: timeline.toUIModel(),
            planType: determinePlanType()
        )
    }
    
    private func determinePlanType() -> PlanType {
        // Determine plan type based on performance
        if performanceSummary.proficiencyLevel == .advanced || performanceSummary.proficiencyLevel == .proficient {
            return .enrichment
        } else if performanceSummary.proficiencyLevel == .minimal || performanceSummary.proficiencyLevel == .basic {
            return .remediation
        } else {
            return .auto
        }
    }
}

extension UIIndividualLearningPlan {
    /// Convert UI ILP back to backend model (for updates)
    /// Note: This creates a backend model from UI data for compatibility
    public func toBackendModel() -> IndividualLearningPlan {
        return IndividualLearningPlan(
            studentInfo: IndividualLearningPlan.StudentInfo(
                msis: studentMSIS,
                name: studentName,
                grade: currentGrade,
                school: "Unknown", // UI doesn't track school
                testDate: createdDate,
                testType: "UI Generated"
            ),
            assessmentDate: createdDate,
            performanceSummary: createPerformanceAnalysis(),
            identifiedGaps: focusAreas.map { $0.toBackendModel() },
            targetStandards: [], // UI doesn't have target standards
            learningObjectives: learningObjectives.map { $0.toBackendModel() },
            interventionStrategies: interventionStrategies.map { $0.toBackendModel() },
            additionalRecommendations: [], // UI doesn't have bonus standards
            predictedOutcomes: [], // UI doesn't track predicted outcomes
            timeline: createBackendTimeline()
        )
    }
    
    private func createPerformanceAnalysis() -> PerformanceAnalysis {
        // Extract basic performance data from summary
        /// overallScore property
        let overallScore = 75.0 // Default placeholder
        return PerformanceAnalysis(
            overallScore: overallScore,
            proficiencyLevel: .passing, // Default to passing
            componentScores: [:], // UI doesn't track component scores separately
            strengthAreas: [], // UI performance summary is simplified
            weakAreas: [] // UI performance summary is simplified
        )
    }
    
    private func createBackendTimeline() -> Timeline {
        /// startDate property
        let startDate = createdDate
        /// endDate property
        let endDate = targetCompletionDate ?? Calendar.current.date(byAdding: .month, value: 9, to: startDate) ?? startDate
        
        return Timeline(
            startDate: startDate,
            endDate: endDate,
            milestones: milestones.map { $0.toBackendModel() }
        )
    }
}

// MARK: - WeakArea / FocusArea Adapters
extension WeakArea {
    /// toUIModel function description
    public func toUIModel() -> UIFocusArea {
        return UIFocusArea(
            subject: extractSubject(from: component),
            description: description,
            components: [component],
            severity: gap,
            standards: []
        )
    }
    
    private func extractSubject(from component: String) -> String {
        if component.contains("MATH") {
            return "Mathematics"
        } else if component.contains("ELA") || component.contains("READING") {
            return "English Language Arts"
        } else {
            return "Unknown"
        }
    }
}

extension UIFocusArea {
    /// toBackendModel function description
    public func toBackendModel() -> WeakArea {
        return WeakArea(
            component: components.first ?? "Unknown", // Use first component or default
            score: 50.0, // Default score for weak area
            gap: severity,
            description: description
        )
    }
}

// MARK: - Learning Objective Adapters
extension ScaffoldedLearningObjective {
    /// toUIModel function description
    public func toUIModel() -> UILearningObjective {
        /// expectations property
        let expectations = UILearningExpectations(
            knowledge: knowledgeObjectives.map { $0.description },
            understanding: understandingObjectives.map { $0.description },
            skills: skillsObjectives.map { $0.description }
        )
        
        return UILearningObjective(
            description: standardDescription,
            standard: standardId,
            expectations: expectations
        )
    }
}

extension UILearningObjective {
    /// toBackendModel function description
    public func toBackendModel() -> ScaffoldedLearningObjective {
        return ScaffoldedLearningObjective(
            standardId: standard ?? "UI-Generated",
            standardDescription: description,
            currentLevel: .basic, // Default current level
            targetLevel: .proficient, // Default target level
            knowledgeObjectives: createLearningTasks(from: expectations?.knowledge),
            understandingObjectives: createLearningTasks(from: expectations?.understanding),
            skillsObjectives: createLearningTasks(from: expectations?.skills),
            keywords: [],
            successCriteria: [description],
            estimatedTimeframe: 4 // Default 4 weeks
        )
    }
    
    private func createLearningTasks(from descriptions: [String]?) -> [LearningTask] {
        return descriptions?.map { desc in
            LearningTask(
                description: desc,
                complexity: .foundational,
                estimatedSessions: 2,
                assessmentType: "Formative",
                resources: []
            )
        } ?? []
    }
}

// MARK: - Milestone Adapters
extension Timeline.Milestone {
    /// toUIModel function description
    public func toUIModel() -> UIMilestone {
        return UIMilestone(
            title: description,
            targetDate: date,
            criteria: [],
            assessmentMethods: [assessmentType]
        )
    }
}

extension UIMilestone {
    /// toBackendModel function description
    public func toBackendModel() -> Timeline.Milestone {
        return Timeline.Milestone(
            date: targetDate,
            description: title,
            assessmentType: assessmentMethods.first ?? "Progress Check"
        )
    }
}

// MARK: - Intervention Strategy Adapters
extension InterventionStrategy {
    /// toUIModel function description
    public func toUIModel() -> UIInterventionStrategy {
        /// interventionType property
        let interventionType: UIInterventionType = {
            switch tier {
            case .universal:
                return .regularSupport
            case .strategic:
                return .targetedIntervention
            case .intensive:
                return .intensiveSupport
            }
        }()
        
        return UIInterventionStrategy(
            title: "Tier \(tier.rawValue) Intervention",
            description: focus.joined(separator: ", "),
            type: interventionType,
            frequency: frequency,
            activities: instructionalApproach
        )
    }
}

extension UIInterventionStrategy {
    /// toBackendModel function description
    public func toBackendModel() -> InterventionStrategy {
        /// tier property
        let tier: InterventionStrategy.InterventionTier = {
            switch type {
            case .regularSupport:
                return .universal
            case .targetedIntervention:
                return .strategic
            case .intensiveSupport:
                return .intensive
            }
        }()
        
        // Create InterventionStrategy with proper struct initialization
        /// strategy property
        let strategy = InterventionStrategy(
            tier: tier,
            frequency: frequency,
            duration: "UI Generated Duration",
            groupSize: "Variable",  
            focus: [title], // Use title as focus area
            instructionalApproach: activities,
            materials: [],
            progressMonitoring: "Weekly assessment"
        )
        return strategy
    }
}

// MARK: - Timeline Adapters
extension Timeline {
    /// toUIModel function description
    public func toUIModel() -> UITimeline {
        /// phases property
        let phases = createPhases()
        return UITimeline(phases: phases)
    }
    
    private func createPhases() -> [UIPhase] {
        /// totalDuration property
        let totalDuration = endDate.timeIntervalSince(startDate)
        /// phaseDuration property
        let phaseDuration = totalDuration / 4.0 // 4 phases
        
        /// phases property
        var phases: [UIPhase] = []
        
        for i in 0..<4 {
            /// phaseStart property
            let phaseStart = startDate.addingTimeInterval(Double(i) * phaseDuration)
            /// phaseEnd property
            let phaseEnd = startDate.addingTimeInterval(Double(i + 1) * phaseDuration)
            
            /// phase property
            let phase = UIPhase(
                name: "Phase \(i + 1)",
                startDate: phaseStart,
                endDate: phaseEnd,
                activities: ["Complete assigned learning objectives", "Progress monitoring"]
            )
            phases.append(phase)
        }
        
        return phases
    }
}

// MARK: - AssessmentComponent Adapters for UI
/// UIAssessmentComponent represents...
public struct UIAssessmentComponent: Sendable {
    /// identifier property
    public let identifier: String
    /// score property
    public let score: Double
    /// scaledScore property
    public let scaledScore: Double // UI expects this property
    /// componentKey property
    public let componentKey: String // UI expects this property
    /// grade property
    public let grade: Int
    /// subject property
    public let subject: String
    /// testProvider property
    public let testProvider: String
    
    public init(
        identifier: String,
        score: Double,
        grade: Int,
        subject: String,
        testProvider: String
    ) {
        self.identifier = identifier
        self.score = score
        self.scaledScore = score // Map score to scaledScore
        self.componentKey = identifier // Map identifier to componentKey
        self.grade = grade
        self.subject = subject
        self.testProvider = testProvider
    }
}

extension AssessmentComponent {
    /// Convert actor-based AssessmentComponent to UI-friendly struct
    public func toUIModel() async -> [UIAssessmentComponent] {
        /// scores property
        let scores = await getAllScores()
        /// componentGrade property
        let componentGrade = await grade
        /// componentSubject property
        let componentSubject = await subject
        /// componentTestProvider property
        let componentTestProvider = await testType.rawValue
        
        return scores.map { key, value in
            UIAssessmentComponent(
                identifier: key,
                score: value,
                grade: componentGrade,
                subject: componentSubject,
                testProvider: componentTestProvider
            )
        }
    }
}

// MARK: - StudentAssessmentData Extensions for UI compatibility
extension StudentAssessmentData {
    /// Get UI-compatible assessment components
    public var uiComponents: [UIAssessmentComponent] {
        return assessments.flatMap { assessment in
            assessment.componentScores.map { key, value in
                UIAssessmentComponent(
                    identifier: key,
                    score: value,
                    grade: grade,
                    subject: assessment.subject,
                    testProvider: assessment.testProvider.rawValue
                )
            }
        }
    }
}

// MARK: - Export Format Disambiguation
extension UILearningPlanModels {
    /// ExportFormat description
    public enum ExportFormat {
        case pdf
        case markdown
        case csv
    }
}

// MARK: - Helper Type for Export Format Disambiguation
/// UILearningPlanModels description
public enum UILearningPlanModels {
    // This namespace helps disambiguate ExportFormat
}