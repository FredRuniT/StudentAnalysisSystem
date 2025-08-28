//
//  File.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//

import Foundation

public struct IndividualLearningPlan: Codable, Sendable {
    public let studentInfo: StudentInfo
    public let assessmentDate: Date
    public let performanceSummary: PerformanceAnalysis
    public let identifiedGaps: [WeakArea]
    public let targetStandards: [TargetStandard]
    public let learningObjectives: [ScaffoldedLearningObjective]
    public let interventionStrategies: [InterventionStrategy]
    public let additionalRecommendations: [BonusStandard]
    public let predictedOutcomes: [PredictedRisk]
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
    
    public struct StudentInfo: Codable, Sendable {
        public let msis: String
        public let name: String
        public let grade: Int
        public let school: String
        public let testDate: Date
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

public struct ScaffoldedLearningObjective: Codable, Sendable {
    public let standardId: String
    public let standardDescription: String
    public let currentLevel: ProficiencyLevel
    public let targetLevel: ProficiencyLevel
    
    // Three-phase scaffolded approach from template
    public let knowledgeObjectives: [LearningTask]  // "What to know"
    public let understandingObjectives: [LearningTask]  // "What to understand"
    public let skillsObjectives: [LearningTask]  // "What to do"
    
    public let keywords: [String]
    public let successCriteria: [String]
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

public struct LearningTask: Codable, Sendable {
    public let description: String
    public let complexity: ComplexityLevel
    public let estimatedSessions: Int
    public let assessmentType: String
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
    
    public enum ComplexityLevel: String, Codable, Sendable {
        case foundational
        case intermediate
        case advanced
    }
}

public struct InterventionStrategy: Codable, Sendable {
    public let tier: InterventionTier
    public let frequency: String
    public let duration: String
    public let groupSize: String
    public let focus: [String] // Standard IDs
    public let instructionalApproach: [String]
    public let materials: [String]
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
    
    public enum InterventionTier: Int, Codable, Sendable {
        case universal = 1  // Tier 1: All students
        case strategic = 2  // Tier 2: Small group
        case intensive = 3  // Tier 3: Individual
    }
}

public struct BonusStandard: Codable, Sendable {
    public let standard: ScaffoldedStandard
    public let rationale: String
    public let type: RecommendationType
    public let expectedBenefit: String
    
    public enum RecommendationType: String, Codable, Sendable {
        case enrichment = "Enrichment"  // For areas of strength
        case prerequisite = "Prerequisite"  // Foundation for weak areas
        case crossCurricular = "Cross-Curricular"  // Based on correlations
        case acceleration = "Acceleration"  // For advanced students
    }
}

// Import the unified Mississippi proficiency levels
import AnalysisCore

// ProficiencyLevel is now defined in MississippiProficiencyLevels.swift as a type alias

public struct PerformanceAnalysis: Codable, Sendable {
    public let overallScore: Double
    public let proficiencyLevel: ProficiencyLevel
    public let componentScores: [String: Double]
    public let strengthAreas: [String]
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

public struct WeakArea: Codable, Sendable, Equatable {
    public let component: String
    public let score: Double
    public let gap: Double
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

public struct TargetStandard: Codable, Sendable {
    public let standardId: String
    public let priority: Int
    public let rationale: String
}

public struct PredictedRisk: Codable, Sendable {
    public let area: String
    public let riskLevel: String
    public let confidence: Double
    public let recommendations: [String]
}

public struct Timeline: Codable, Sendable {
    public let startDate: Date
    public let endDate: Date
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
    
    public struct Milestone: Codable, Sendable {
        public let date: Date
        public let description: String
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
