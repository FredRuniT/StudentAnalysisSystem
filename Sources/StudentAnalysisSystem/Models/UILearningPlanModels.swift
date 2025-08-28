import Foundation

// MARK: - Simplified UI Models for ILP Display
// These are simplified versions of the full ILP models for UI purposes

/// UIIndividualLearningPlan represents...
public struct UIIndividualLearningPlan: Identifiable, Sendable {
    /// id property
    public let id: UUID
    /// studentMSIS property
    public let studentMSIS: String
    /// studentName property
    public let studentName: String
    /// currentGrade property
    public let currentGrade: Int
    /// targetGrade property
    public let targetGrade: Int
    /// createdDate property
    public let createdDate: Date
    /// targetCompletionDate property
    public let targetCompletionDate: Date?
    /// performanceSummary property
    public let performanceSummary: [String]
    /// focusAreas property
    public let focusAreas: [UIFocusArea]
    /// learningObjectives property
    public let learningObjectives: [UILearningObjective]
    /// milestones property
    public let milestones: [UIMilestone]
    /// interventionStrategies property
    public let interventionStrategies: [UIInterventionStrategy]
    /// timeline property
    public let timeline: UITimeline?
    /// planType property
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

/// UIFocusArea represents...
public struct UIFocusArea: Identifiable, Sendable {
    /// id property
    public let id: String
    /// subject property
    public let subject: String
    /// description property
    public let description: String
    /// components property
    public let components: [String]
    /// severity property
    public let severity: Double
    /// standards property
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

/// UILearningObjective represents...
public struct UILearningObjective: Identifiable, Sendable {
    /// id property
    public let id = UUID()
    /// description property
    public let description: String
    /// standard property
    public let standard: String?
    /// expectations property
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

/// UILearningExpectations represents...
public struct UILearningExpectations: Sendable {
    /// knowledge property
    public let knowledge: [String]?
    /// understanding property
    public let understanding: [String]?
    /// skills property
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

/// UIMilestone represents...
public struct UIMilestone: Identifiable, Sendable {
    /// id property
    public let id = UUID().uuidString
    /// title property
    public let title: String
    /// targetDate property
    public let targetDate: Date
    /// criteria property
    public let criteria: [String]
    /// assessmentMethods property
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

/// UIInterventionStrategy represents...
public struct UIInterventionStrategy: Identifiable, Sendable {
    /// id property
    public let id = UUID()
    /// title property
    public let title: String
    /// description property
    public let description: String
    /// type property
    public let type: UIInterventionType
    /// frequency property
    public let frequency: String
    /// activities property
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

/// UIInterventionType description
public enum UIInterventionType: String, CaseIterable, Sendable {
    case intensiveSupport = "Intensive Support"
    case targetedIntervention = "Targeted Intervention"
    case regularSupport = "Regular Support"
}

/// UITimeline represents...
public struct UITimeline: Sendable {
    /// phases property
    public let phases: [UIPhase]
    
    public init(phases: [UIPhase]) {
        self.phases = phases
    }
}

/// UIPhase represents...
public struct UIPhase: Identifiable, Sendable {
    /// id property
    public let id = UUID()
    /// name property
    public let name: String
    /// startDate property
    public let startDate: Date
    /// endDate property
    public let endDate: Date
    /// activities property
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
/// ExportFormat description
public enum ExportFormat {
    case pdf
    case markdown
    case csv
}