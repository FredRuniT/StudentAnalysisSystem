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
    
    public struct StudentInfo: Codable, Sendable {
        public let msis: String
        public let name: String
        public let grade: Int
        public let school: String
        public let testDate: Date
        public let testType: TestProvider
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
}

public struct LearningTask: Codable, Sendable {
    public let description: String
    public let complexity: ComplexityLevel
    public let estimatedSessions: Int
    public let assessmentType: String
    public let resources: [String]
    
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
