//
//  AccelerationAnalyzer.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//

import Foundation
import MLX

public actor AccelerationAnalyzer {
    private let correlationEngine: CorrelationAnalyzer
    private let standardsRepository: StandardsRepository
    private let masteryThreshold = 85.0 // Configurable
    private let advancedThreshold = 95.0
    
    public func identifyAccelerationCandidates(
        studentData: [StudentAssessmentData],
        correlationModel: ValidatedCorrelationModel
    ) async -> [AccelerationCandidate] {
        var candidates: [AccelerationCandidate] = []
        
        for student in studentData {
            let masteredComponents = identifyMasteredComponents(student)
            
            if !masteredComponents.isEmpty {
                // Use correlations to predict future success areas
                let predictedStrengths = await predictFutureStrengths(
                    masteredComponents: masteredComponents,
                    model: correlationModel
                )
                
                // Create acceleration profile
                let profile = await buildAccelerationProfile(
                    student: student,
                    masteredComponents: masteredComponents,
                    predictions: predictedStrengths
                )
                
                if profile.readinessScore > 0.7 {
                    candidates.append(AccelerationCandidate(
                        studentInfo: student.studentInfo,
                        profile: profile,
                        pathways: await generatePathways(profile)
                    ))
                }
            }
        }
        
        return candidates
    }
    
    private func identifyMasteredComponents(
        _ student: StudentAssessmentData
    ) -> [MasteredComponent] {
        student.componentScores.compactMap { component, score in
            guard score >= masteryThreshold else { return nil }
            
            return MasteredComponent(
                component: component,
                score: score,
                masteryLevel: score >= advancedThreshold ? .advanced : .proficient,
                consistencyAcrossTime: checkConsistency(student, component)
            )
        }
    }
    
    private func predictFutureStrengths(
        masteredComponents: [MasteredComponent],
        model: ValidatedCorrelationModel
    ) async -> [PredictedStrength] {
        var predictions: [PredictedStrength] = []
        
        for mastered in masteredComponents {
            // Find what this mastery predicts
            let correlations = model.getStrongPositiveCorrelations(
                from: mastered.component,
                threshold: 0.6
            )
            
            for correlation in correlations {
                predictions.append(PredictedStrength(
                    sourceComponent: mastered.component,
                    targetComponent: correlation.target,
                    correlationStrength: correlation.value,
                    confidence: correlation.confidence,
                    predictedPerformance: calculatePredictedPerformance(
                        currentScore: mastered.score,
                        correlation: correlation
                    )
                ))
            }
        }
        
        return predictions.sorted { $0.confidence > $1.confidence }
    }
    
    private func generatePathways(
        _ profile: AccelerationProfile
    ) async -> [AccelerationPathway] {
        var pathways: [AccelerationPathway] = []
        
        // Vertical Acceleration (grade advancement in subject)
        if profile.eligibleForGradeAcceleration {
            pathways.append(await generateVerticalPathway(profile))
        }
        
        // Horizontal Enrichment (deeper exploration at grade level)
        pathways.append(await generateEnrichmentPathway(profile))
        
        // Cross-curricular Connections
        if profile.crossCurricularStrengths.count > 1 {
            pathways.append(await generateCrossCurricularPathway(profile))
        }
        
        // Compacted Curriculum (faster pace through standards)
        if profile.learningVelocity > 1.5 {
            pathways.append(await generateCompactedPathway(profile))
        }
        
        return pathways
    }
}

public struct AccelerationCandidate: Sendable {
    public let studentInfo: StudentInfo
    public let profile: AccelerationProfile
    public let pathways: [AccelerationPathway]
}

public struct AccelerationProfile: Sendable {
    public let masteredComponents: [MasteredComponent]
    public let predictedStrengths: [PredictedStrength]
    public let readinessScore: Double // 0-1
    public let learningVelocity: Double // Compared to grade level pace
    public let consistencyScore: Double // Stability of high performance
    public let eligibleForGradeAcceleration: Bool
    public let crossCurricularStrengths: [String]
}
