import Foundation
import AnalysisCore

public struct VisualizationData {
    
    public struct CorrelationHeatmap: Codable {
        public let components: [String]
        public let matrix: [[Double]]
        public let colorScale: ColorScale
        
        public struct ColorScale: Codable {
            public let min: Double
            public let max: Double
            public let midpoint: Double
            public let minColor: String // Hex color
            public let maxColor: String
            public let midColor: String
        }
        
        public init(correlationMatrix: [[Double]], componentLabels: [String]) {
            self.components = componentLabels
            self.matrix = correlationMatrix
            self.colorScale = ColorScale(
                min: -1.0,
                max: 1.0,
                midpoint: 0.0,
                minColor: "#FF0000", // Red for negative
                maxColor: "#0000FF", // Blue for positive
                midColor: "#FFFFFF"  // White for zero
            )
        }
    }
    
    public struct ProgressionChart: Codable {
        public let studentID: String
        public let dataPoints: [DataPoint]
        public let trendLine: TrendLine?
        public let predictedPoints: [DataPoint]
        
        public struct DataPoint: Codable {
            public let grade: Int
            public let year: Int
            public let component: String
            public let score: Double
            public let proficiencyLevel: String
        }
        
        public struct TrendLine: Codable {
            public let slope: Double
            public let intercept: Double
            public let r2: Double
            public let equation: String
        }
    }
    
    public struct RiskDistribution: Codable {
        public let categories: [RiskCategory]
        public let totalStudents: Int
        
        public struct RiskCategory: Codable {
            public let level: String
            public let count: Int
            public let percentage: Double
            public let color: String
        }
        
        public static func from(riskLevels: [RiskLevel]) -> RiskDistribution {
            let total = riskLevels.count
            let grouped = Dictionary(grouping: riskLevels) { $0 }
            
            let categories = [RiskLevel.critical, .high, .moderate, .low].map { level in
                let count = grouped[level]?.count ?? 0
                return RiskCategory(
                    level: level.rawValue,
                    count: count,
                    percentage: Double(count) / Double(total) * 100,
                    color: colorForRiskLevel(level)
                )
            }
            
            return RiskDistribution(categories: categories, totalStudents: total)
        }
        
        private static func colorForRiskLevel(_ level: RiskLevel) -> String {
            switch level {
            case .critical: return "#FF0000"
            case .high: return "#FF8800"
            case .moderate: return "#FFCC00"
            case .low: return "#00CC00"
            }
        }
    }
    
    public struct ComponentNetwork: Codable {
        public let nodes: [Node]
        public let edges: [Edge]
        
        public struct Node: Codable {
            public let id: String
            public let label: String
            public let grade: Int
            public let subject: String
            public let size: Double
            public let color: String
        }
        
        public struct Edge: Codable {
            public let source: String
            public let target: String
            public let weight: Double
            public let correlation: Double
            public let color: String
        }
        
        public static func from(correlations: [ComponentCorrelationMap]) -> ComponentNetwork {
            var nodes: [String: Node] = [:]
            var edges: [Edge] = []
            
            for map in correlations {
                // Add source node
                let sourceId = map.sourceComponent.description
                if nodes[sourceId] == nil {
                    nodes[sourceId] = Node(
                        id: sourceId,
                        label: map.sourceComponent.component,
                        grade: map.sourceComponent.grade,
                        subject: map.sourceComponent.subject,
                        size: Double(map.correlations.count),
                        color: colorForSubject(map.sourceComponent.subject)
                    )
                }
                
                // Add edges for correlations
                for correlation in map.correlations.prefix(5) {
                    let targetId = correlation.target.description
                    
                    // Add target node
                    if nodes[targetId] == nil {
                        nodes[targetId] = Node(
                            id: targetId,
                            label: correlation.target.component,
                            grade: correlation.target.grade,
                            subject: correlation.target.subject,
                            size: 1.0,
                            color: colorForSubject(correlation.target.subject)
                        )
                    }
                    
                    // Add edge
                    edges.append(Edge(
                        source: sourceId,
                        target: targetId,
                        weight: abs(correlation.correlation),
                        correlation: correlation.correlation,
                        color: correlation.correlation > 0 ? "#0088CC" : "#CC0088"
                    ))
                }
            }
            
            return ComponentNetwork(
                nodes: Array(nodes.values),
                edges: edges
            )
        }
        
        private static func colorForSubject(_ subject: String) -> String {
            switch subject.uppercased() {
            case "MATH", "MATHEMATICS": return "#FF6B6B"
            case "ELA", "ENGLISH", "READING": return "#4ECDC4"
            case "SCIENCE": return "#95E77E"
            case "ALGEBRA I", "ALGEBRA_I": return "#FFD93D"
            case "ENGLISH II", "ENGLISH_II": return "#6C5CE7"
            default: return "#A8A8A8"
            }
        }
    }
}