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
    /// Note: This is a simplified conversion - full implementation would require
    /// proper mapping of all UI data back to structured backend models
    public func toBackendModel() -> IndividualLearningPlan {
        // This would need to be implemented with proper data parsing
        // For now, we'll create a minimal placeholder that won't be called in normal UI flow
        fatalError("toBackendModel not fully implemented - UI to backend conversion requires additional mapping logic")
    }
}

// MARK: - WeakArea / FocusArea Adapters
extension WeakArea {
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
    public func toBackendModel() -> WeakArea {
        fatalError("toBackendModel not fully implemented - requires proper backend model construction")
    }
}

// MARK: - Learning Objective Adapters
extension ScaffoldedLearningObjective {
    public func toUIModel() -> UILearningObjective {
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
    public func toBackendModel() -> ScaffoldedLearningObjective {
        fatalError("toBackendModel not fully implemented - requires proper backend model construction")
    }
}

// MARK: - Milestone Adapters
extension Timeline.Milestone {
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
    public func toBackendModel() -> Timeline.Milestone {
        fatalError("toBackendModel not fully implemented - requires proper backend model construction")
    }
}

// MARK: - Intervention Strategy Adapters
extension InterventionStrategy {
    public func toUIModel() -> UIInterventionStrategy {
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
    public func toBackendModel() -> InterventionStrategy {
        fatalError("toBackendModel not fully implemented - requires proper backend model construction")
    }
}

// MARK: - Timeline Adapters
extension Timeline {
    public func toUIModel() -> UITimeline {
        let phases = createPhases()
        return UITimeline(phases: phases)
    }
    
    private func createPhases() -> [UIPhase] {
        let totalDuration = endDate.timeIntervalSince(startDate)
        let phaseDuration = totalDuration / 4.0 // 4 phases
        
        var phases: [UIPhase] = []
        
        for i in 0..<4 {
            let phaseStart = startDate.addingTimeInterval(Double(i) * phaseDuration)
            let phaseEnd = startDate.addingTimeInterval(Double(i + 1) * phaseDuration)
            
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
public struct UIAssessmentComponent: Sendable {
    public let identifier: String
    public let score: Double
    public let scaledScore: Double // UI expects this property
    public let componentKey: String // UI expects this property
    public let grade: Int
    public let subject: String
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
        let scores = await getAllScores()
        let componentGrade = await grade
        let componentSubject = await subject
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
    public enum ExportFormat {
        case pdf
        case markdown
        case csv
    }
}

// MARK: - Helper Type for Export Format Disambiguation
public enum UILearningPlanModels {
    // This namespace helps disambiguate ExportFormat
}