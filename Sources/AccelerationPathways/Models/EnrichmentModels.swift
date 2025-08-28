//
//  EnrichmentModels.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//

import Foundation

/// EnrichmentPlan represents...
public struct EnrichmentPlan: Codable, Sendable {
    /// type property
    public let type: AccelerationType
    /// title property
    public let title: String
    /// objectives property
    public let objectives: [EnrichmentObjective]
    /// assessmentStrategy property
    public let assessmentStrategy: AssessmentStrategy
    /// supportStructure property
    public let supportStructure: SupportStructure
    /// estimatedDuration property
    public let estimatedDuration: String
    /// requiredResources property
    public let requiredResources: [String]
    
    /// AccelerationType description
    public enum AccelerationType: String, Codable, Sendable {
        case verticalAcceleration = "Grade Acceleration"
        case horizontalEnrichment = "Depth and Complexity"
        case compactedCurriculum = "Compacted Pacing"
        case crossCurricular = "Interdisciplinary"
    }
}

/// EnrichmentObjective represents...
public struct EnrichmentObjective: Codable, Sendable {
    /// standardId property
    public let standardId: String
    /// description property
    public let description: String
    /// complexity property
    public let complexity: ComplexityLevel
    /// activities property
    public let activities: [EnrichmentActivity]
    /// successCriteria property
    public let successCriteria: [String]
    
    /// ComplexityLevel description
    public enum ComplexityLevel: String, Codable, Sendable {
        case aboveGradeLevel = "Above Grade Level"
        case extendedGradeLevel = "Extended Grade Level"
        case compacted = "Compacted"
        case interdisciplinary = "Interdisciplinary"
    }
}

/// EnrichmentActivity represents...
public struct EnrichmentActivity: Codable, Sendable {
    /// type property
    public let type: ActivityType
    /// title property
    public let title: String
    /// description property
    public let description: String
    /// estimatedTime property
    public let estimatedTime: String
    /// resources property
    public let resources: [String]
    /// differentiationOptions property
    public let differentiationOptions: [String]
    
    /// ActivityType description
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

/// MasteredComponent represents...
public struct MasteredComponent: Sendable {
    /// component property
    public let component: String
    /// score property
    public let score: Double
    /// masteryLevel property
    public let masteryLevel: MasteryLevel
    /// consistencyAcrossTime property
    public let consistencyAcrossTime: Double // 0-1
    
    /// MasteryLevel description
    public enum MasteryLevel: String, Sendable {
        case proficient = "Proficient"
        case advanced = "Advanced"
        case exceptional = "Exceptional"
    }
}

/// PredictedStrength represents...
public struct PredictedStrength: Sendable {
    /// sourceComponent property
    public let sourceComponent: String
    /// targetComponent property
    public let targetComponent: String
    /// correlationStrength property
    public let correlationStrength: Double
    /// confidence property
    public let confidence: Double
    /// predictedPerformance property
    public let predictedPerformance: PerformancePrediction
}

/// AccelerationPathway represents...
public struct AccelerationPathway: Sendable {
    /// type property
    public let type: PathwayType
    /// description property
    public let description: String
    /// gradeAdvancement property
    public let gradeAdvancement: Int
    /// enrichmentDepth property
    public let enrichmentDepth: EnrichmentDepth
    /// accelerationRate property
    public let accelerationRate: Double
    /// crossCurricularConnections property
    public let crossCurricularConnections: [String]
    /// readinessIndicators property
    public let readinessIndicators: [String]
    /// potentialChallenges property
    public let potentialChallenges: [String]
    /// supportNeeded property
    public let supportNeeded: [String]
    
    /// PathwayType description
    public enum PathwayType: String, Sendable {
        case vertical = "Vertical Acceleration"
        case horizontal = "Horizontal Enrichment"
        case crossCurricular = "Cross-Curricular Integration"
        case compacted = "Compacted Curriculum"
    }
}

/// EnrichmentDepth description
public enum EnrichmentDepth: String, Codable, Sendable {
    case surface = "Surface Extension"
    case deep = "Deep Exploration"
    case transfer = "Transfer Application"
    case creation = "Creative Innovation"
}
