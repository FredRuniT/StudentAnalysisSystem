import Foundation

// MARK: - Simplified UI Models for ILP Display
// These are simplified versions of the full ILP models for UI purposes

public struct UIIndividualLearningPlan: Identifiable, Sendable {
    public let id: UUID
    public let studentMSIS: String
    public let studentName: String
    public let currentGrade: Int
    public let targetGrade: Int
    public let createdDate: Date
    public let targetCompletionDate: Date?
    public let performanceSummary: [String]
    public let focusAreas: [UIFocusArea]
    public let learningObjectives: [UILearningObjective]
    public let milestones: [UIMilestone]
    public let interventionStrategies: [UIInterventionStrategy]
    public let timeline: UITimeline?
    public let planType: PlanType
    
    public init(
        id: UUID = UUID(),
        studentMSIS: String,
        studentName: String,
        currentGrade: Int,
        targetGrade: Int,
        createdDate: Date = Date(),
        targetCompletionDate: Date? = nil,
        performanceSummary: [String] = [],
        focusAreas: [UIFocusArea] = [],
        learningObjectives: [UILearningObjective] = [],
        milestones: [UIMilestone] = [],
        interventionStrategies: [UIInterventionStrategy] = [],
        timeline: UITimeline? = nil,
        planType: PlanType = .auto
    ) {
        self.id = id
        self.studentMSIS = studentMSIS
        self.studentName = studentName
        self.currentGrade = currentGrade
        self.targetGrade = targetGrade
        self.createdDate = createdDate
        self.targetCompletionDate = targetCompletionDate
        self.performanceSummary = performanceSummary
        self.focusAreas = focusAreas
        self.learningObjectives = learningObjectives
        self.milestones = milestones
        self.interventionStrategies = interventionStrategies
        self.timeline = timeline
        self.planType = planType
    }
}

public struct UIFocusArea: Identifiable, Sendable {
    public let id: String
    public let subject: String
    public let description: String
    public let components: [String]
    public let severity: Double
    public let standards: [String]
    
    public init(
        id: String = UUID().uuidString,
        subject: String,
        description: String,
        components: [String] = [],
        severity: Double,
        standards: [String] = []
    ) {
        self.id = id
        self.subject = subject
        self.description = description
        self.components = components
        self.severity = severity
        self.standards = standards
    }
}

public struct UILearningObjective: Identifiable, Sendable {
    public let id = UUID()
    public let description: String
    public let standard: String?
    public let expectations: UILearningExpectations?
    
    public init(
        description: String,
        standard: String? = nil,
        expectations: UILearningExpectations? = nil
    ) {
        self.description = description
        self.standard = standard
        self.expectations = expectations
    }
}

public struct UILearningExpectations: Sendable {
    public let knowledge: [String]?
    public let understanding: [String]?
    public let skills: [String]?
    
    public init(
        knowledge: [String]? = nil,
        understanding: [String]? = nil,
        skills: [String]? = nil
    ) {
        self.knowledge = knowledge
        self.understanding = understanding
        self.skills = skills
    }
}

public struct UIMilestone: Identifiable, Sendable {
    public let id = UUID().uuidString
    public let title: String
    public let targetDate: Date
    public let criteria: [String]
    public let assessmentMethods: [String]
    
    public init(
        title: String,
        targetDate: Date,
        criteria: [String] = [],
        assessmentMethods: [String] = []
    ) {
        self.title = title
        self.targetDate = targetDate
        self.criteria = criteria
        self.assessmentMethods = assessmentMethods
    }
}

public struct UIInterventionStrategy: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let type: UIInterventionType
    public let frequency: String
    public let activities: [String]
    
    public init(
        title: String,
        description: String,
        type: UIInterventionType,
        frequency: String,
        activities: [String] = []
    ) {
        self.title = title
        self.description = description
        self.type = type
        self.frequency = frequency
        self.activities = activities
    }
}

public enum UIInterventionType: String, CaseIterable, Sendable {
    case intensiveSupport = "Intensive Support"
    case targetedIntervention = "Targeted Intervention"
    case regularSupport = "Regular Support"
}

public struct UITimeline: Sendable {
    public let phases: [UIPhase]
    
    public init(phases: [UIPhase]) {
        self.phases = phases
    }
}

public struct UIPhase: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let startDate: Date
    public let endDate: Date
    public let activities: [String]
    
    public init(
        name: String,
        startDate: Date,
        endDate: Date,
        activities: [String] = []
    ) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.activities = activities
    }
}

// MARK: - Export Format
public enum ExportFormat {
    case pdf
    case markdown
    case csv
}