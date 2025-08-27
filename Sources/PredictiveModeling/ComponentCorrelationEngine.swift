import Foundation
import AnalysisCore
import StatisticalEngine

public actor ComponentCorrelationEngine {
    private let correlationAnalyzer: CorrelationAnalyzer
    private let mlxAccelerator: MLXAccelerator
    private let configuration: SystemConfiguration
    
    public init(configuration: SystemConfiguration? = nil) {
        self.correlationAnalyzer = CorrelationAnalyzer()
        self.mlxAccelerator = MLXAccelerator()
        self.configuration = configuration ?? SystemConfiguration.default
    }
    
    public struct ComponentCorrelationMap: Sendable, Codable {
        public let sourceComponent: ComponentIdentifier
        public let correlations: [TargetCorrelation]
        public let strongestPath: CorrelationPath?
        
        public struct TargetCorrelation: Sendable, Codable {
            public let target: ComponentIdentifier
            public let correlation: Double
            public let confidence: Double
            public let sampleSize: Int
            public let timeGap: Int // Years between assessments
        }
        
        public struct CorrelationPath: Sendable, Codable {
            public let components: [ComponentIdentifier]
            public let cumulativeCorrelation: Double
            public let pathway: String
        }
    }
    
    /// Get correlations for a specific component from a pre-computed model
    public nonisolated func getCorrelationsForComponent(
        componentKey: String,
        correlationMaps: [ComponentCorrelationMap],
        threshold: Double = 0.3
    ) -> [(targetComponent: String, correlation: Double, confidence: Double)] {
        // Find the map for this component
        guard let map = correlationMaps.first(where: { 
            "\($0.sourceComponent.grade)_\($0.sourceComponent.subject)_\($0.sourceComponent.component)" == componentKey 
        }) else {
            return []
        }
        
        // Extract correlations above threshold
        var results: [(targetComponent: String, correlation: Double, confidence: Double)] = []
        
        for correlation in map.correlations {
            if abs(correlation.correlation) >= threshold {
                let targetKey = "Grade_\(correlation.target.grade)_\(correlation.target.subject)_\(correlation.target.component)"
                results.append((
                    targetComponent: targetKey,
                    correlation: correlation.correlation,
                    confidence: correlation.confidence
                ))
            }
        }
        
        return results.sorted { abs($0.correlation) > abs($1.correlation) }
    }
    
    public func discoverAllCorrelations(
        studentData: [StudentLongitudinalData],
        minCorrelation: Double? = nil,
        minSampleSize: Int? = nil
    ) async throws -> [ComponentCorrelationMap] {
        // Use configuration values if not provided
        let minCorr = minCorrelation ?? configuration.correlation.minimumCorrelation
        let minSample = minSampleSize ?? configuration.correlation.minimumSampleSize
        
        // Extract all unique components
        let allComponents = extractAllComponents(from: studentData)
        var correlationMaps: [ComponentCorrelationMap] = []
        
        // Process each component as a source
        await withTaskGroup(of: ComponentCorrelationMap?.self) { group in
            for source in allComponents {
                group.addTask {
                    return await self.buildCorrelationMap(
                        source: source,
                        allComponents: allComponents,
                        studentData: studentData,
                        minCorrelation: minCorr,
                        minSampleSize: minSample
                    )
                }
            }
            
            for await map in group {
                if let map = map {
                    correlationMaps.append(map)
                }
            }
        }
        
        return correlationMaps.sorted { $0.strongestPath?.cumulativeCorrelation ?? 0 > $1.strongestPath?.cumulativeCorrelation ?? 0 }
    }
    
    private func buildCorrelationMap(
        source: ComponentIdentifier,
        allComponents: [ComponentIdentifier],
        studentData: [StudentLongitudinalData],
        minCorrelation: Double,
        minSampleSize: Int
    ) async -> ComponentCorrelationMap? {
        var targetCorrelations: [ComponentCorrelationMap.TargetCorrelation] = []
        
        for target in allComponents {
            // Skip same component or earlier grades
            guard target != source && target.grade >= source.grade else { continue }
            
            // Calculate correlation
            let correlation = await correlationAnalyzer.calculateComponentCorrelations(
                source: source.toPair(),
                target: target.toPair(),
                studentData: studentData
            )
            
            // Filter by thresholds
            if abs(correlation.pearsonR) >= minCorrelation && 
               correlation.sampleSize >= minSampleSize {
                // Calculate confidence with NaN protection
                let confidence = {
                    let pValue = correlation.pValue
                    guard !pValue.isNaN && !pValue.isInfinite else { return 0.0 }
                    let result = 1.0 - pValue
                    return result.isNaN || result.isInfinite ? 0.0 : max(0.0, min(1.0, result))
                }()
                
                targetCorrelations.append(
                    ComponentCorrelationMap.TargetCorrelation(
                        target: target,
                        correlation: correlation.pearsonR,
                        confidence: confidence,
                        sampleSize: correlation.sampleSize,
                        timeGap: target.grade - source.grade
                    )
                )
            }
        }
        
        guard !targetCorrelations.isEmpty else { return nil }
        
        // Find strongest correlation path
        let strongestPath = findStrongestPath(
            from: source,
            correlations: targetCorrelations
        )
        
        return ComponentCorrelationMap(
            sourceComponent: source,
            correlations: targetCorrelations.sorted { abs($0.correlation) > abs($1.correlation) },
            strongestPath: strongestPath
        )
    }
    
    private func findStrongestPath(
        from source: ComponentIdentifier,
        correlations: [ComponentCorrelationMap.TargetCorrelation]
    ) -> ComponentCorrelationMap.CorrelationPath? {
        guard let strongest = correlations.max(by: { abs($0.correlation) < abs($1.correlation) }) else {
            return nil
        }
        
        let pathway = "\(source.description) → \(strongest.target.description)"
        
        return ComponentCorrelationMap.CorrelationPath(
            components: [source, strongest.target],
            cumulativeCorrelation: strongest.correlation,
            pathway: pathway
        )
    }
    
    private func extractAllComponents(from studentData: [StudentLongitudinalData]) -> [ComponentIdentifier] {
        var components = Set<ComponentIdentifier>()
        
        for student in studentData {
            for assessment in student.assessments {
                for componentKey in assessment.componentScores.keys {
                    components.insert(
                        ComponentIdentifier(
                            grade: assessment.grade,
                            subject: assessment.subject,
                            component: componentKey,
                            testProvider: assessment.testProvider
                        )
                    )
                }
            }
        }
        
        return Array(components).sorted { $0.grade < $1.grade || ($0.grade == $1.grade && $0.component < $1.component) }
    }
}

// ComponentIdentifier is defined in AnalysisCore
// Extension to add toPair functionality
extension ComponentIdentifier {
    public func toPair() -> ComponentPair {
        ComponentPair(
            grade: grade,
            year: nil,
            subject: subject,
            component: component,
            testProvider: testProvider
        )
    }
}