import AnalysisCore
import Foundation

/// VisualizationData represents...
public struct VisualizationData {
    
    /// CorrelationHeatmap represents...
    public struct CorrelationHeatmap: Codable {
        /// components property
        public let components: [String]
        /// matrix property
        public let matrix: [[Double]]
        /// colorScale property
        public let colorScale: ColorScale
        
        /// ColorScale represents...
        public struct ColorScale: Codable {
            /// min property
            public let min: Double
            /// max property
            public let max: Double
            /// midpoint property
            public let midpoint: Double
            /// minColor property
            public let minColor: String // Hex color
            /// maxColor property
            public let maxColor: String
            /// midColor property
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
    
    /// ProgressionChart represents...
    public struct ProgressionChart: Codable {
        /// studentID property
        public let studentID: String
        /// dataPoints property
        public let dataPoints: [DataPoint]
        /// trendLine property
        public let trendLine: TrendLine?
        /// predictedPoints property
        public let predictedPoints: [DataPoint]
        
        /// DataPoint represents...
        public struct DataPoint: Codable {
            /// grade property
            public let grade: Int
            /// year property
            public let year: Int
            /// component property
            public let component: String
            /// score property
            public let score: Double
            /// proficiencyLevel property
            public let proficiencyLevel: String
        }
        
        /// TrendLine represents...
        public struct TrendLine: Codable {
            /// slope property
            public let slope: Double
            /// intercept property
            public let intercept: Double
            /// r2 property
            public let r2: Double
            /// equation property
            public let equation: String
        }
    }
    
    /// RiskDistribution represents...
    public struct RiskDistribution: Codable {
        /// categories property
        public let categories: [RiskCategory]
        /// totalStudents property
        public let totalStudents: Int
        
        /// RiskCategory represents...
        public struct RiskCategory: Codable {
            /// level property
            public let level: String
            /// count property
            public let count: Int
            /// percentage property
            public let percentage: Double
            /// color property
            public let color: String
        }
        
        /// from function description
        public static func from(riskLevels: [RiskLevel]) -> RiskDistribution {
            /// total property
            let total = riskLevels.count
            /// grouped property
            let grouped = Dictionary(grouping: riskLevels) { $0 }
            
            /// categories property
            let categories = [RiskLevel.critical, .high, .moderate, .low].map { level in
                /// count property
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
    
    /// ComponentNetwork represents...
    public struct ComponentNetwork: Codable {
        /// nodes property
        public let nodes: [Node]
        /// edges property
        public let edges: [Edge]
        
        /// Node represents...
        public struct Node: Codable {
            /// id property
            public let id: String
            /// label property
            public let label: String
            /// grade property
            public let grade: Int
            /// subject property
            public let subject: String
            /// size property
            public let size: Double
            /// color property
            public let color: String
        }
        
        /// Edge represents...
        public struct Edge: Codable {
            /// source property
            public let source: String
            /// target property
            public let target: String
            /// weight property
            public let weight: Double
            /// correlation property
            public let correlation: Double
            /// color property
            public let color: String
        }
        
        /// from function description
        public static func from(correlations: [ComponentCorrelationMap]) -> ComponentNetwork {
            /// nodes property
            var nodes: [String: Node] = [:]
            /// edges property
            var edges: [Edge] = []
            
            for map in correlations {
                // Add source node
                /// sourceId property
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
                    /// targetId property
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