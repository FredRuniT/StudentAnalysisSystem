import Foundation

// MARK: - Missing Types for Blueprint Integration
// These types bridge correlation analysis with ILP generation

/// Enhanced correlation model with confidence metrics for blueprint integration
@available(iOS 15.0, macOS 12.0, *)
public struct EnhancedCorrelationModel: Codable, Sendable, Equatable {
    public let base: CorrelationData
    public let sampleSize: Int
    public let confidenceInterval: ConfidenceInterval
    public let pValue: Double
    public let isStatisticallySignificant: Bool
    public let significance: SignificanceLevel
    public let validationMetrics: ValidationMetrics
    
    public init(
        base: CorrelationData,
        sampleSize: Int,
        confidenceInterval: ConfidenceInterval,
        pValue: Double,
        validationMetrics: ValidationMetrics
    ) {
        self.base = base
        self.sampleSize = sampleSize
        self.confidenceInterval = confidenceInterval
        self.pValue = pValue
        self.isStatisticallySignificant = pValue < 0.05
        self.significance = SignificanceLevel(pValue: pValue)
        self.validationMetrics = validationMetrics
    }
}

/// Correlation data structure
public struct CorrelationData: Codable, Sendable, Equatable {
    public let fromComponent: String
    public let toComponent: String
    public let correlation: Double
    public let fromGrade: Int
    public let toGrade: Int
    public let subject: String
    
    public init(
        fromComponent: String,
        toComponent: String,
        correlation: Double,
        fromGrade: Int,
        toGrade: Int,
        subject: String
    ) {
        self.fromComponent = fromComponent
        self.toComponent = toComponent
        self.correlation = correlation
        self.fromGrade = fromGrade
        self.toGrade = toGrade
        self.subject = subject
    }
}

/// Confidence interval for correlation
public struct ConfidenceInterval: Codable, Sendable, Equatable {
    public let lower: Double
    public let upper: Double
    public let level: Double // 0.95 for 95% confidence
    
    public init(lower: Double, upper: Double, level: Double = 0.95) {
        self.lower = lower
        self.upper = upper
        self.level = level
    }
}

/// Significance level indicators
public enum SignificanceLevel: String, Codable, Sendable {
    case highlySignificant = "⭐⭐" // p < 0.001
    case verySignificant = "⭐"    // p < 0.01
    case significant = "☆"         // p < 0.05
    case notSignificant = ""       // p >= 0.05
    
    public init(pValue: Double) {
        switch pValue {
        case ..<0.001: self = .highlySignificant
        case ..<0.01: self = .verySignificant
        case ..<0.05: self = .significant
        default: self = .notSignificant
        }
    }
}

/// Validation metrics for correlation model
public struct ValidationMetrics: Codable, Sendable, Equatable {
    public let r2Score: Double
    public let rmse: Double
    public let mae: Double
    public let crossValidationScore: Double
    
    public init(r2Score: Double, rmse: Double, mae: Double, crossValidationScore: Double) {
        self.r2Score = r2Score
        self.rmse = rmse
        self.mae = mae
        self.crossValidationScore = crossValidationScore
    }
}

// MARK: - Learning Objective

/// A specific, measurable learning objective tied to standards
@available(iOS 15.0, macOS 12.0, *)
public struct LearningObjective: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let standardId: String
    public let description: String
    public let targetLevel: ProficiencyLevel
    public let focusArea: FocusArea
    public let activities: [String]
    public let timeEstimate: String
    public let assessmentCriteria: [String]
    public let resources: [String]
    
    public init(
        id: UUID = UUID(),
        standardId: String,
        description: String,
        targetLevel: ProficiencyLevel,
        focusArea: FocusArea,
        activities: [String],
        timeEstimate: String,
        assessmentCriteria: [String] = [],
        resources: [String] = []
    ) {
        self.id = id
        self.standardId = standardId
        self.description = description
        self.targetLevel = targetLevel
        self.focusArea = focusArea
        self.activities = activities
        self.timeEstimate = timeEstimate
        self.assessmentCriteria = assessmentCriteria
        self.resources = resources
    }
    
    /// Create from scaffolding expectations
    public init(
        standard: String,
        description: String,
        expectations: LearningExpectations,
        focusArea: FocusArea,
        studentLevel: ProficiencyLevel
    ) {
        self.id = UUID()
        self.standardId = standard
        self.description = description
        self.targetLevel = studentLevel.next()
        self.focusArea = focusArea
        
        // Select activities based on focus area
        switch focusArea {
        case .knowledge:
            self.activities = expectations.knowledge.prefix(3).map { String($0) }
        case .understanding:
            self.activities = expectations.understanding.prefix(3).map { String($0) }
        case .skills:
            self.activities = expectations.skills.prefix(3).map { String($0) }
        case .practice:
            self.activities = expectations.skills.prefix(2).map { "Practice: \($0)" } + 
                            expectations.understanding.prefix(1).map { String($0) }
        case .enrichment:
            self.activities = expectations.skills.suffix(2).map { "Advanced: \($0)" }
        }
        
        // Estimate time based on proficiency gap
        self.timeEstimate = studentLevel.timeToNext()
        
        // Generate assessment criteria
        self.assessmentCriteria = [
            "Demonstrates \(focusArea.rawValue) of \(standard)",
            "Achieves \(targetLevel.threshold * 100)% accuracy",
            "Completes tasks independently"
        ]
        
        // Add default resources
        self.resources = [
            "Textbook Chapter",
            "Online Practice",
            "Manipulatives/Visual Aids"
        ]
    }
}

// MARK: - Predicted Outcome

/// Predicted outcome based on correlation analysis
@available(iOS 15.0, macOS 12.0, *)
public struct PredictedOutcome: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let component: String
    public let futureGrade: Int
    public let correlationStrength: Double
    public let impact: ImpactLevel
    public let probability: Double
    public let timeframe: String
    public let preventionStrategy: String?
    
    public enum ImpactLevel: String, Codable, Sendable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        
        init(correlation: Double) {
            switch abs(correlation) {
            case 0.8...1.0: self = .critical
            case 0.6..<0.8: self = .high
            case 0.4..<0.6: self = .medium
            default: self = .low
            }
        }
    }
    
    public init(
        id: UUID = UUID(),
        component: String,
        futureGrade: Int,
        correlationStrength: Double,
        probability: Double,
        timeframe: String,
        preventionStrategy: String? = nil
    ) {
        self.id = id
        self.component = component
        self.futureGrade = futureGrade
        self.correlationStrength = correlationStrength
        self.impact = ImpactLevel(correlation: correlationStrength)
        self.probability = probability
        self.timeframe = timeframe
        self.preventionStrategy = preventionStrategy
    }
}

// MARK: - Milestone

/// A checkpoint for measuring progress (aligned with 9-week periods)
@available(iOS 15.0, macOS 12.0, *)
public struct Milestone: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let title: String
    public let targetDate: Date
    public let phase: InterventionPhase
    public let successCriteria: [String]
    public let evaluationType: EvaluationType
    public let reportCardPeriod: Int // 1-4 for quarters
    public let expectedProgress: Double // Percentage
    
    public enum InterventionPhase: String, Codable, Sendable, CaseIterable {
        case immediate = "Immediate Intervention"
        case shortTerm = "Short-term Development"
        case longTerm = "Long-term Mastery"
        case maintenance = "Maintenance"
    }
    
    public enum EvaluationType: String, Codable, Sendable {
        case formative = "Formative Assessment"
        case summative = "Summative Assessment"
        case benchmark = "Benchmark Test"
        case reportCard = "Report Card Period"
        case stateTest = "State Assessment"
    }
    
    public init(
        id: UUID = UUID(),
        title: String,
        targetDate: Date,
        phase: InterventionPhase,
        successCriteria: [String],
        evaluationType: EvaluationType,
        reportCardPeriod: Int,
        expectedProgress: Double
    ) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.phase = phase
        self.successCriteria = successCriteria
        self.evaluationType = evaluationType
        self.reportCardPeriod = reportCardPeriod
        self.expectedProgress = expectedProgress
    }
    
    /// Create milestone for 9-week checkpoint
    public static func nineWeekMilestone(
        weekNumber: Int,
        phase: InterventionPhase,
        startDate: Date,
        objectives: [LearningObjective]
    ) -> Milestone {
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .weekOfYear, value: weekNumber, to: startDate) ?? startDate
        let reportCardPeriod = (weekNumber / 9) + 1
        
        let title = "Week \(weekNumber) - \(phase.rawValue)"
        let successCriteria = objectives.prefix(3).map { $0.assessmentCriteria.first ?? "" }
        
        let expectedProgress: Double = {
            switch phase {
            case .immediate: return 0.25
            case .shortTerm: return 0.50
            case .longTerm: return 0.75
            case .maintenance: return 0.90
            }
        }()
        
        return Milestone(
            id: UUID(),
            title: title,
            targetDate: targetDate,
            phase: phase,
            successCriteria: successCriteria,
            evaluationType: weekNumber % 9 == 0 ? .reportCard : .formative,
            reportCardPeriod: reportCardPeriod,
            expectedProgress: expectedProgress
        )
    }
}

// MARK: - Progress Evaluation

/// Evaluation of student progress at a milestone
@available(iOS 15.0, macOS 12.0, *)
public struct ProgressEvaluation: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let milestoneId: UUID
    public let evaluationDate: Date
    public let evaluator: String
    public let evaluatorRole: EvaluatorRole
    public let scores: [String: Double] // Component -> Score
    public let overallProgress: Double
    public let currentLevel: ProficiencyLevel
    public let notes: String
    public let attachments: [String] // File paths or URLs
    public let nextSteps: [String]
    
    public enum EvaluatorRole: String, Codable, Sendable {
        case teacher = "Teacher"
        case parent = "Parent"
        case specialist = "Specialist"
        case selfAssessment = "Self-Assessment"
    }
    
    public init(
        id: UUID = UUID(),
        milestoneId: UUID,
        evaluationDate: Date,
        evaluator: String,
        evaluatorRole: EvaluatorRole,
        scores: [String: Double],
        overallProgress: Double,
        currentLevel: ProficiencyLevel,
        notes: String,
        attachments: [String] = [],
        nextSteps: [String] = []
    ) {
        self.id = id
        self.milestoneId = milestoneId
        self.evaluationDate = evaluationDate
        self.evaluator = evaluator
        self.evaluatorRole = evaluatorRole
        self.scores = scores
        self.overallProgress = overallProgress
        self.currentLevel = currentLevel
        self.notes = notes
        self.attachments = attachments
        self.nextSteps = nextSteps
    }
}

// MARK: - Helper Extensions

extension ProficiencyLevel {
    /// Get the next proficiency level
    func next() -> ProficiencyLevel {
        switch self {
        case .minimal: return .basic
        case .basic: return .passing
        case .passing: return .proficient
        case .proficient: return .advanced
        case .advanced: return .advanced
        }
    }
    
    /// Estimate time to reach next level
    func timeToNext() -> String {
        switch self {
        case .minimal: return "10-12 weeks"
        case .basic: return "8-10 weeks"
        case .passing: return "6-8 weeks"
        case .proficient: return "4-6 weeks"
        case .advanced: return "2-4 weeks"
        }
    }
}