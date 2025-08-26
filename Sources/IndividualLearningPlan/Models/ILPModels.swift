//
//  File.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//

import Foundation
import AnalysisCore

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
        public let testType: String // Using String instead of TestProvider for Codable
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

// Missing types that need to be defined
public enum ProficiencyLevel: String, Codable, Sendable {
    case advanced = "Advanced"
    case proficient = "Proficient"
    case basic = "Basic"
    case belowBasic = "Below Basic"
    case minimal = "Minimal"
}

public struct PerformanceAnalysis: Codable, Sendable {
    public let overallScore: Double
    public let proficiencyLevel: ProficiencyLevel
    public let componentScores: [String: Double]
    public let strengthAreas: [String]
    public let weakAreas: [String]
}

public struct WeakArea: Codable, Sendable, Equatable {
    public let component: String
    public let score: Double
    public let gap: Double
    public let description: String
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
    
    public struct Milestone: Codable, Sendable {
        public let date: Date
        public let description: String
        public let assessmentType: String
    }
}
