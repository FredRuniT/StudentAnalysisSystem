import AnalysisCore
import Foundation
//
//  File.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//


/// IndividualLearningPlan represents...
public struct IndividualLearningPlan: Codable, Sendable {
    /// studentInfo property
    public let studentInfo: StudentInfo
    /// assessmentDate property
    public let assessmentDate: Date
    /// performanceSummary property
    public let performanceSummary: PerformanceAnalysis
    /// identifiedGaps property
    public let identifiedGaps: [WeakArea]
    /// targetStandards property
    public let targetStandards: [TargetStandard]
    /// learningObjectives property
    public let learningObjectives: [ScaffoldedLearningObjective]
    /// interventionStrategies property
    public let interventionStrategies: [InterventionStrategy]
    /// additionalRecommendations property
    public let additionalRecommendations: [BonusStandard]
    /// predictedOutcomes property
    public let predictedOutcomes: [PredictedRisk]
    /// timeline property
    public let timeline: Timeline
    
    public init(
        studentInfo: StudentInfo,
        assessmentDate: Date,
        performanceSummary: PerformanceAnalysis,
        identifiedGaps: [WeakArea] = [],
        targetStandards: [TargetStandard] = [],
        learningObjectives: [ScaffoldedLearningObjective] = [],
        interventionStrategies: [InterventionStrategy] = [],
        additionalRecommendations: [BonusStandard] = [],
        predictedOutcomes: [PredictedRisk] = [],
        timeline: Timeline
    ) {
        self.studentInfo = studentInfo
        self.assessmentDate = assessmentDate
        self.performanceSummary = performanceSummary
        self.identifiedGaps = identifiedGaps
        self.targetStandards = targetStandards
        self.learningObjectives = learningObjectives
        self.interventionStrategies = interventionStrategies
        self.additionalRecommendations = additionalRecommendations
        self.predictedOutcomes = predictedOutcomes
        self.timeline = timeline
    }
    
    /// StudentInfo represents...
    public struct StudentInfo: Codable, Sendable {
        /// msis property
        public let msis: String
        /// name property
        public let name: String
        /// grade property
        public let grade: Int
        /// school property
        public let school: String
        /// testDate property
        public let testDate: Date
        /// testType property
        public let testType: String // Using String instead of TestProvider for Codable
        
        public init(
            msis: String,
            name: String,
            grade: Int,
            school: String,
            testDate: Date,
            testType: String
        ) {
            self.msis = msis
            self.name = name
            self.grade = grade
            self.school = school
            self.testDate = testDate
            self.testType = testType
        }
    }
}

/// ScaffoldedLearningObjective represents...
public struct ScaffoldedLearningObjective: Codable, Sendable {
    /// standardId property
    public let standardId: String
    /// standardDescription property
    public let standardDescription: String
    /// currentLevel property
    public let currentLevel: ProficiencyLevel
    /// targetLevel property
    public let targetLevel: ProficiencyLevel
    
    // Three-phase scaffolded approach from template
    /// knowledgeObjectives property
    public let knowledgeObjectives: [LearningTask]  // "What to know"
    /// understandingObjectives property
    public let understandingObjectives: [LearningTask]  // "What to understand"
    /// skillsObjectives property
    public let skillsObjectives: [LearningTask]  // "What to do"
    
    /// keywords property
    public let keywords: [String]
    /// successCriteria property
    public let successCriteria: [String]
    /// estimatedTimeframe property
    public let estimatedTimeframe: Int // in weeks
    
    public init(
        standardId: String,
        standardDescription: String,
        currentLevel: ProficiencyLevel,
        targetLevel: ProficiencyLevel,
        knowledgeObjectives: [LearningTask] = [],
        understandingObjectives: [LearningTask] = [],
        skillsObjectives: [LearningTask] = [],
        keywords: [String] = [],
        successCriteria: [String] = [],
        estimatedTimeframe: Int = 4
    ) {
        self.standardId = standardId
        self.standardDescription = standardDescription
        self.currentLevel = currentLevel
        self.targetLevel = targetLevel
        self.knowledgeObjectives = knowledgeObjectives
        self.understandingObjectives = understandingObjectives
        self.skillsObjectives = skillsObjectives
        self.keywords = keywords
        self.successCriteria = successCriteria
        self.estimatedTimeframe = estimatedTimeframe
    }
}

/// LearningTask represents...
public struct LearningTask: Codable, Sendable {
    /// description property
    public let description: String
    /// complexity property
    public let complexity: ComplexityLevel
    /// estimatedSessions property
    public let estimatedSessions: Int
    /// assessmentType property
    public let assessmentType: String
    /// resources property
    public let resources: [String]
    
    public init(
        description: String,
        complexity: ComplexityLevel = .foundational,
        estimatedSessions: Int = 1,
        assessmentType: String = "Formative",
        resources: [String] = []
    ) {
        self.description = description
        self.complexity = complexity
        self.estimatedSessions = estimatedSessions
        self.assessmentType = assessmentType
        self.resources = resources
    }
    
    /// ComplexityLevel description
    public enum ComplexityLevel: String, Codable, Sendable {
        case foundational
        case intermediate
        case advanced
    }
}

/// InterventionStrategy represents...
public struct InterventionStrategy: Codable, Sendable {
    /// tier property
    public let tier: InterventionTier
    /// frequency property
    public let frequency: String
    /// duration property
    public let duration: String
    /// groupSize property
    public let groupSize: String
    /// focus property
    public let focus: [String] // Standard IDs
    /// instructionalApproach property
    public let instructionalApproach: [String]
    /// materials property
    public let materials: [String]
    /// progressMonitoring property
    public let progressMonitoring: String
    
    public init(
        tier: InterventionTier,
        frequency: String,
        duration: String,
        groupSize: String,
        focus: [String],
        instructionalApproach: [String],
        materials: [String],
        progressMonitoring: String
    ) {
        self.tier = tier
        self.frequency = frequency
        self.duration = duration
        self.groupSize = groupSize
        self.focus = focus
        self.instructionalApproach = instructionalApproach
        self.materials = materials
        self.progressMonitoring = progressMonitoring
    }
    
    /// InterventionTier description
    public enum InterventionTier: Int, Codable, Sendable {
        case universal = 1  // Tier 1: All students
        case strategic = 2  // Tier 2: Small group
        case intensive = 3  // Tier 3: Individual
    }
}

/// BonusStandard represents...
public struct BonusStandard: Codable, Sendable {
    /// standard property
    public let standard: ScaffoldedStandard
    /// rationale property
    public let rationale: String
    /// type property
    public let type: RecommendationType
    /// expectedBenefit property
    public let expectedBenefit: String
    
    /// RecommendationType description
    public enum RecommendationType: String, Codable, Sendable {
        case enrichment = "Enrichment"  // For areas of strength
        case prerequisite = "Prerequisite"  // Foundation for weak areas
        case crossCurricular = "Cross-Curricular"  // Based on correlations
        case acceleration = "Acceleration"  // For advanced students
    }
}

// Import the unified Mississippi proficiency levels

// ProficiencyLevel is now defined in MississippiProficiencyLevels.swift as a type alias

/// PerformanceAnalysis represents...
public struct PerformanceAnalysis: Codable, Sendable {
    /// overallScore property
    public let overallScore: Double
    /// proficiencyLevel property
    public let proficiencyLevel: ProficiencyLevel
    /// componentScores property
    public let componentScores: [String: Double]
    /// strengthAreas property
    public let strengthAreas: [String]
    /// weakAreas property
    public let weakAreas: [String]
    
    public init(
        overallScore: Double,
        proficiencyLevel: ProficiencyLevel,
        componentScores: [String: Double] = [:],
        strengthAreas: [String] = [],
        weakAreas: [String] = []
    ) {
        self.overallScore = overallScore
        self.proficiencyLevel = proficiencyLevel
        self.componentScores = componentScores
        self.strengthAreas = strengthAreas
        self.weakAreas = weakAreas
    }
}

/// WeakArea represents...
public struct WeakArea: Codable, Sendable, Equatable {
    /// component property
    public let component: String
    /// score property
    public let score: Double
    /// gap property
    public let gap: Double
    /// description property
    public let description: String
    
    public init(
        component: String,
        score: Double,
        gap: Double,
        description: String
    ) {
        self.component = component
        self.score = score
        self.gap = gap
        self.description = description
    }
}

/// TargetStandard represents...
public struct TargetStandard: Codable, Sendable {
    /// standardId property
    public let standardId: String
    /// priority property
    public let priority: Int
    /// rationale property
    public let rationale: String
}

/// PredictedRisk represents...
public struct PredictedRisk: Codable, Sendable {
    /// area property
    public let area: String
    /// riskLevel property
    public let riskLevel: String
    /// confidence property
    public let confidence: Double
    /// recommendations property
    public let recommendations: [String]
}

/// Timeline represents...
public struct Timeline: Codable, Sendable {
    /// startDate property
    public let startDate: Date
    /// endDate property
    public let endDate: Date
    /// milestones property
    public let milestones: [Milestone]
    
    public init(
        startDate: Date,
        endDate: Date,
        milestones: [Milestone] = []
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.milestones = milestones
    }
    
    /// Milestone represents...
    public struct Milestone: Codable, Sendable {
        /// date property
        public let date: Date
        /// description property
        public let description: String
        /// assessmentType property
        public let assessmentType: String
        
        public init(
            date: Date,
            description: String,
            assessmentType: String
        ) {
            self.date = date
            self.description = description
            self.assessmentType = assessmentType
        }
    }
}
