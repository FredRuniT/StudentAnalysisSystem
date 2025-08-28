import AnalysisCore
import Foundation
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
    
    /// ComponentCorrelationMap represents...
    public struct ComponentCorrelationMap: Sendable, Codable {
        /// sourceComponent property
        public let sourceComponent: ComponentIdentifier
        /// correlations property
        public let correlations: [TargetCorrelation]
        /// strongestPath property
        public let strongestPath: CorrelationPath?
        
        /// TargetCorrelation represents...
        public struct TargetCorrelation: Sendable, Codable {
            /// target property
            public let target: ComponentIdentifier
            /// correlation property
            public let correlation: Double
            /// confidence property
            public let confidence: Double
            /// sampleSize property
            public let sampleSize: Int
            /// timeGap property
            public let timeGap: Int // Years between assessments
        }
        
        /// CorrelationPath represents...
        public struct CorrelationPath: Sendable, Codable {
            /// components property
            public let components: [ComponentIdentifier]
            /// cumulativeCorrelation property
            public let cumulativeCorrelation: Double
            /// pathway property
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
        /// map property
        guard let map = correlationMaps.first(where: { 
            "\($0.sourceComponent.grade)_\($0.sourceComponent.subject)_\($0.sourceComponent.component)" == componentKey 
        }) else {
            return []
        }
        
        // Extract correlations above threshold
        /// results property
        var results: [(targetComponent: String, correlation: Double, confidence: Double)] = []
        
        for correlation in map.correlations {
            if abs(correlation.correlation) >= threshold {
                /// targetKey property
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
    
    /// discoverAllCorrelations function description
    public func discoverAllCorrelations(
        studentData: [StudentLongitudinalData],
        minCorrelation: Double? = nil,
        minSampleSize: Int? = nil
    ) async throws -> [ComponentCorrelationMap] {
        // Use configuration values if not provided
        /// minCorr property
        let minCorr = minCorrelation ?? configuration.correlation.minimumCorrelation
        /// minSample property
        let minSample = minSampleSize ?? configuration.correlation.minimumSampleSize
        
        // Extract all unique components
        /// allComponents property
        let allComponents = extractAllComponents(from: studentData)
        /// correlationMaps property
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
                /// map property
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
        /// targetCorrelations property
        var targetCorrelations: [ComponentCorrelationMap.TargetCorrelation] = []
        
        for target in allComponents {
            // Skip same component or earlier grades
            guard target != source && target.grade >= source.grade else { continue }
            
            // Calculate correlation
            /// correlation property
            let correlation = await correlationAnalyzer.calculateComponentCorrelations(
                source: source.toPair(),
                target: target.toPair(),
                studentData: studentData
            )
            
            // Filter by thresholds
            if abs(correlation.pearsonR) >= minCorrelation && 
               correlation.sampleSize >= minSampleSize {
                // Calculate confidence with NaN protection
                /// confidence property
                let confidence = {
                    /// pValue property
                    let pValue = correlation.pValue
                    guard !pValue.isNaN && !pValue.isInfinite else { return 0.0 }
                    /// result property
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
        /// strongestPath property
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
        /// strongest property
        guard let strongest = correlations.max(by: { abs($0.correlation) < abs($1.correlation) }) else {
            return nil
        }
        
        /// pathway property
        let pathway = "\(source.description) → \(strongest.target.description)"
        
        return ComponentCorrelationMap.CorrelationPath(
            components: [source, strongest.target],
            cumulativeCorrelation: strongest.correlation,
            pathway: pathway
        )
    }
    
    private func extractAllComponents(from studentData: [StudentLongitudinalData]) -> [ComponentIdentifier] {
        /// components property
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
    /// toPair function description
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