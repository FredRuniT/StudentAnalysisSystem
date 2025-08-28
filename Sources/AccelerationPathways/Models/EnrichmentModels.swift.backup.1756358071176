//
//  EnrichmentModels.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//

import Foundation

public struct EnrichmentPlan: Codable, Sendable {
    public let type: AccelerationType
    public let title: String
    public let objectives: [EnrichmentObjective]
    public let assessmentStrategy: AssessmentStrategy
    public let supportStructure: SupportStructure
    public let estimatedDuration: String
    public let requiredResources: [String]
    
    public enum AccelerationType: String, Codable, Sendable {
        case verticalAcceleration = "Grade Acceleration"
        case horizontalEnrichment = "Depth and Complexity"
        case compactedCurriculum = "Compacted Pacing"
        case crossCurricular = "Interdisciplinary"
    }
}

public struct EnrichmentObjective: Codable, Sendable {
    public let standardId: String
    public let description: String
    public let complexity: ComplexityLevel
    public let activities: [EnrichmentActivity]
    public let successCriteria: [String]
    
    public enum ComplexityLevel: String, Codable, Sendable {
        case aboveGradeLevel = "Above Grade Level"
        case extendedGradeLevel = "Extended Grade Level"
        case compacted = "Compacted"
        case interdisciplinary = "Interdisciplinary"
    }
}

public struct EnrichmentActivity: Codable, Sendable {
    public let type: ActivityType
    public let title: String
    public let description: String
    public let estimatedTime: String
    public let resources: [String]
    public let differentiationOptions: [String]
    
    public enum ActivityType: String, Codable, Sendable {
        case assessment
        case independentStudy
        case project
        case research
        case peerTutoring
        case creative
        case acceleratedInstruction
        case extension
        case competition
        case mentorship
    }
}

public struct MasteredComponent: Sendable {
    public let component: String
    public let score: Double
    public let masteryLevel: MasteryLevel
    public let consistencyAcrossTime: Double // 0-1
    
    public enum MasteryLevel: String, Sendable {
        case proficient = "Proficient"
        case advanced = "Advanced"
        case exceptional = "Exceptional"
    }
}

public struct PredictedStrength: Sendable {
    public let sourceComponent: String
    public let targetComponent: String
    public let correlationStrength: Double
    public let confidence: Double
    public let predictedPerformance: PerformancePrediction
}

public struct AccelerationPathway: Sendable {
    public let type: PathwayType
    public let description: String
    public let gradeAdvancement: Int
    public let enrichmentDepth: EnrichmentDepth
    public let accelerationRate: Double
    public let crossCurricularConnections: [String]
    public let readinessIndicators: [String]
    public let potentialChallenges: [String]
    public let supportNeeded: [String]
    
    public enum PathwayType: String, Sendable {
        case vertical = "Vertical Acceleration"
        case horizontal = "Horizontal Enrichment"
        case crossCurricular = "Cross-Curricular Integration"
        case compacted = "Compacted Curriculum"
    }
}

public enum EnrichmentDepth: String, Codable, Sendable {
    case surface = "Surface Extension"
    case deep = "Deep Exploration"
    case transfer = "Transfer Application"
    case creation = "Creative Innovation"
}
