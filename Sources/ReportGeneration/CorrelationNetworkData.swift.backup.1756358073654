import Foundation
import AnalysisCore

/// Filtered correlation data structure optimized for network visualization
@MainActor
public struct FilteredCorrelationResult: Sendable, Identifiable {
    public let id: UUID
    public let source: ComponentIdentifier
    public let target: ComponentIdentifier
    public let correlation: Double
    public let confidence: Double
    public let sampleSize: Int
    public let significance: SignificanceLevel
    
    public init(
        source: ComponentIdentifier,
        target: ComponentIdentifier,
        correlation: Double,
        confidence: Double,
        sampleSize: Int
    ) {
        self.id = UUID()
        self.source = source
        self.target = target
        self.correlation = correlation
        self.confidence = confidence
        self.sampleSize = sampleSize
        
        // Calculate significance based on confidence (confidence = 1 - p-value)
        let pValue = 1.0 - confidence
        if pValue < 0.01 {
            self.significance = .highlySignificant
        } else if pValue < 0.05 {
            self.significance = .significant
        } else {
            self.significance = .notSignificant
        }
    }
    
    public enum SignificanceLevel: String, Sendable, CaseIterable {
        case highlySignificant = "⭐"
        case significant = "☆"
        case notSignificant = ""
        
        public var description: String {
            switch self {
            case .highlySignificant: return "Highly Significant (p<0.01)"
            case .significant: return "Significant (p<0.05)"
            case .notSignificant: return "Not Significant"
            }
        }
    }
    
    public var strengthCategory: CorrelationStrength {
        let absR = abs(correlation)
        switch absR {
        case 0.9...1.0: return .veryStrong
        case 0.7..<0.9: return .strong
        case 0.5..<0.7: return .moderate
        case 0.3..<0.5: return .weak
        default: return .veryWeak
        }
    }
    
    public enum CorrelationStrength: String, Sendable, CaseIterable {
        case veryStrong = "Very Strong (r>0.9)"
        case strong = "Strong (r>0.7)"
        case moderate = "Moderate (r>0.5)"
        case weak = "Weak (r>0.3)"
        case veryWeak = "Very Weak (r<0.3)"
        
        public var threshold: Double {
            switch self {
            case .veryStrong: return 0.9
            case .strong: return 0.7
            case .moderate: return 0.5
            case .weak: return 0.3
            case .veryWeak: return 0.0
            }
        }
        
        public var color: String {
            switch self {
            case .veryStrong: return "#34C759" // Green
            case .strong: return "#007AFF"     // Blue
            case .moderate: return "#FF9500"   // Orange
            case .weak: return "#FF3B30"       // Red
            case .veryWeak: return "#8E8E93"   // Gray
            }
        }
    }
}

/// Network node representing an assessment component
@MainActor
public struct NetworkNode: Sendable, Identifiable {
    public let id: ComponentIdentifier
    public let component: ComponentIdentifier
    public var position: CGPoint
    public var velocity: CGPoint
    public let connectionCount: Int
    public let subjectColor: String
    
    public init(component: ComponentIdentifier, connectionCount: Int) {
        self.id = component
        self.component = component
        self.position = CGPoint.zero
        self.velocity = CGPoint.zero
        self.connectionCount = connectionCount
        
        // Color code by subject
        switch component.subject.uppercased() {
        case "ELA", "ENGLISH", "READING":
            self.subjectColor = "#0084FF" // Blue
        case "MATH", "MATHEMATICS":
            self.subjectColor = "#AF52DE" // Purple
        case "SCIENCE":
            self.subjectColor = "#34C759" // Green
        case "SOCIAL":
            self.subjectColor = "#FF9500" // Orange
        default:
            self.subjectColor = "#8E8E93" // Gray
        }
    }
    
    public var nodeSize: Double {
        // Size based on connection count: 8-25 points
        return min(25.0, max(8.0, 8.0 + Double(connectionCount) * 0.3))
    }
    
    public mutating func updatePosition(_ newPosition: CGPoint) {
        self.position = newPosition
    }
    
    public mutating func updateVelocity(_ newVelocity: CGPoint) {
        self.velocity = newVelocity
    }
}

/// Network edge representing a correlation
@MainActor
public struct NetworkEdge: Sendable, Identifiable {
    public let id: UUID
    public let source: ComponentIdentifier
    public let target: ComponentIdentifier
    public let strength: Double
    public let significance: FilteredCorrelationResult.SignificanceLevel
    
    public init(from correlation: FilteredCorrelationResult) {
        self.id = correlation.id
        self.source = correlation.source
        self.target = correlation.target
        self.strength = correlation.correlation
        self.significance = correlation.significance
    }
    
    public var lineWidth: Double {
        // Map correlation strength to line width (1-6 points)
        return 1.0 + abs(strength) * 5.0
    }
    
    public var opacity: Double {
        // Base opacity + correlation strength
        return 0.3 + abs(strength) * 0.4
    }
    
    public var color: String {
        let absStrength = abs(strength)
        if absStrength >= 0.7 {
            return "#32D74B" // Green for strong
        } else if absStrength >= 0.5 {
            return "#FF9F0A" // Orange for moderate
        } else {
            return "#8E8E93" // Gray for weak
        }
    }
}

/// Correlation filtering and processing pipeline
@MainActor
public class CorrelationNetworkProcessor: ObservableObject {
    @Published public private(set) var filteredCorrelations: [FilteredCorrelationResult] = []
    @Published public private(set) var networkNodes: [NetworkNode] = []
    @Published public private(set) var networkEdges: [NetworkEdge] = []
    @Published public private(set) var isProcessing = false
    
    // Filter settings
    @Published public var correlationThreshold: Double = 0.7
    @Published public var selectedGrades: Set<Int> = []
    @Published public var selectedSubjects: Set<String> = []
    @Published public var maxCorrelations: Int = 18000
    
    private var allCorrelations: [ComponentCorrelationMap] = []
    
    public init() {}
    
    /// Load correlation data from ComponentCorrelationMap array
    public func loadCorrelationData(_ correlationMaps: [ComponentCorrelationMap]) {
        self.allCorrelations = correlationMaps
        processCorrelations()
    }
    
    /// Process and filter correlations based on current settings
    public func processCorrelations() {
        isProcessing = true
        
        Task {
            let filtered = await filterCorrelations()
            let (nodes, edges) = await buildNetworkData(from: filtered)
            
            await MainActor.run {
                self.filteredCorrelations = filtered
                self.networkNodes = nodes
                self.networkEdges = edges
                self.isProcessing = false
            }
        }
    }
    
    private func filterCorrelations() async -> [FilteredCorrelationResult] {
        var results: [FilteredCorrelationResult] = []
        
        for correlationMap in allCorrelations {
            // Apply grade filter
            if !selectedGrades.isEmpty && !selectedGrades.contains(correlationMap.sourceComponent.grade) {
                continue
            }
            
            // Apply subject filter
            if !selectedSubjects.isEmpty && !selectedSubjects.contains(correlationMap.sourceComponent.subject) {
                continue
            }
            
            for correlation in correlationMap.correlations {
                // Apply threshold filter
                if abs(correlation.correlation) < correlationThreshold {
                    continue
                }
                
                // Apply target grade/subject filters
                if !selectedGrades.isEmpty && !selectedGrades.contains(correlation.target.grade) {
                    continue
                }
                
                if !selectedSubjects.isEmpty && !selectedSubjects.contains(correlation.target.subject) {
                    continue
                }
                
                let filtered = FilteredCorrelationResult(
                    source: correlationMap.sourceComponent,
                    target: correlation.target,
                    correlation: correlation.correlation,
                    confidence: correlation.confidence,
                    sampleSize: correlation.sampleSize
                )
                
                results.append(filtered)
                
                // Respect max correlations limit for performance
                if results.count >= maxCorrelations {
                    break
                }
            }
            
            if results.count >= maxCorrelations {
                break
            }
        }
        
        // Sort by correlation strength (descending)
        return results.sorted { abs($0.correlation) > abs($1.correlation) }
    }
    
    private func buildNetworkData(from correlations: [FilteredCorrelationResult]) async -> ([NetworkNode], [NetworkEdge]) {
        var componentConnections: [ComponentIdentifier: Int] = [:]
        var nodes: [ComponentIdentifier: NetworkNode] = [:]
        var edges: [NetworkEdge] = []
        
        // Count connections for each component
        for correlation in correlations {
            componentConnections[correlation.source, default: 0] += 1
            componentConnections[correlation.target, default: 0] += 1
        }
        
        // Create nodes
        for (component, connectionCount) in componentConnections {
            nodes[component] = NetworkNode(component: component, connectionCount: connectionCount)
        }
        
        // Create edges
        for correlation in correlations {
            edges.append(NetworkEdge(from: correlation))
        }
        
        return (Array(nodes.values), edges)
    }
    
    /// Update filter threshold and reprocess
    public func updateThreshold(_ newThreshold: Double) {
        correlationThreshold = newThreshold
        processCorrelations()
    }
    
    /// Update grade filter
    public func updateGradeFilter(_ grades: Set<Int>) {
        selectedGrades = grades
        processCorrelations()
    }
    
    /// Update subject filter
    public func updateSubjectFilter(_ subjects: Set<String>) {
        selectedSubjects = subjects
        processCorrelations()
    }
    
    /// Get summary statistics
    public var filterSummary: String {
        let nodeCount = networkNodes.count
        let edgeCount = networkEdges.count
        return "Nodes: \(nodeCount), Edges: \(edgeCount), Threshold: \(String(format: "%.2f", correlationThreshold))"
    }
    
    // MARK: - Physics Integration Methods
    
    /// Initialize random positions for nodes
    public func initializeNodePositions(canvasSize: CGSize) {
        let margin = 50.0
        let width = canvasSize.width - 2 * margin
        let height = canvasSize.height - 2 * margin
        
        print("🚀 Initializing positions for \(networkNodes.count) nodes in canvas \(canvasSize)")
        
        for i in 0..<networkNodes.count {
            let x = margin + Double.random(in: 0...1) * width
            let y = margin + Double.random(in: 0...1) * height
            networkNodes[i].updatePosition(CGPoint(x: x, y: y))
            networkNodes[i].updateVelocity(.zero)
            print("Node \(i) positioned at (\(x), \(y))")
        }
    }
    
    /// Perform one physics simulation step
    public func performPhysicsStep(
        temperature: Double,
        deltaTime: Double,
        repulsionStrength: Double,
        springLength: Double,
        springConstant: Double,
        damping: Double,
        canvasSize: CGSize
    ) {
        let nodeCount = networkNodes.count
        guard nodeCount > 0 else { return }
        
        var forces = Array(repeating: CGPoint.zero, count: nodeCount)
        
        // Calculate repulsive forces between all nodes
        for i in 0..<nodeCount {
            let nodeA = networkNodes[i]
            
            for j in (i+1)..<nodeCount {
                let nodeB = networkNodes[j]
                let dx = nodeA.position.x - nodeB.position.x
                let dy = nodeA.position.y - nodeB.position.y
                let distance = sqrt(dx * dx + dy * dy)
                
                if distance > 0 && distance < repulsionStrength * 2 {
                    let force = repulsionStrength / max(1.0, distance * distance)
                    let normalizedDx = dx / distance
                    let normalizedDy = dy / distance
                    
                    forces[i].x += normalizedDx * force
                    forces[i].y += normalizedDy * force
                    forces[j].x -= normalizedDx * force
                    forces[j].y -= normalizedDy * force
                }
            }
        }
        
        // Calculate attractive forces from edges
        var nodeIndices: [ComponentIdentifier: Int] = [:]
        for (index, node) in networkNodes.enumerated() {
            nodeIndices[node.id] = index
        }
        
        for edge in networkEdges {
            guard let sourceIndex = nodeIndices[edge.source],
                  let targetIndex = nodeIndices[edge.target] else {
                continue
            }
            
            let sourceNode = networkNodes[sourceIndex]
            let targetNode = networkNodes[targetIndex]
            
            let dx = targetNode.position.x - sourceNode.position.x
            let dy = targetNode.position.y - sourceNode.position.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance > 0 {
                let displacement = distance - springLength
                let force = springConstant * displacement * abs(edge.strength)
                
                let normalizedDx = dx / distance
                let normalizedDy = dy / distance
                
                forces[sourceIndex].x += normalizedDx * force
                forces[sourceIndex].y += normalizedDy * force
                forces[targetIndex].x -= normalizedDx * force
                forces[targetIndex].y -= normalizedDy * force
            }
        }
        
        // Apply forces and update positions
        let margin = 20.0
        
        for i in 0..<nodeCount {
            var velocity = networkNodes[i].velocity
            
            // Apply force to velocity
            velocity.x += forces[i].x * deltaTime
            velocity.y += forces[i].y * deltaTime
            
            // Apply damping
            velocity.x *= damping
            velocity.y *= damping
            
            // Limit velocity based on temperature
            let maxVelocity = temperature * 10.0
            let velocityMagnitude = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
            if velocityMagnitude > maxVelocity {
                velocity.x = (velocity.x / velocityMagnitude) * maxVelocity
                velocity.y = (velocity.y / velocityMagnitude) * maxVelocity
            }
            
            // Update position
            var newPosition = networkNodes[i].position
            newPosition.x += velocity.x * deltaTime
            newPosition.y += velocity.y * deltaTime
            
            // Keep nodes within canvas bounds
            newPosition.x = max(margin, min(canvasSize.width - margin, newPosition.x))
            newPosition.y = max(margin, min(canvasSize.height - margin, newPosition.y))
            
            networkNodes[i].updatePosition(newPosition)
            networkNodes[i].updateVelocity(velocity)
        }
    }
}

