import Foundation
import SwiftUI
import AnalysisCore

/// Force-directed layout implementation using Fruchterman-Reingold algorithm
@MainActor
public class ForceDirectedLayout: ObservableObject {
    // Physics parameters
    @Published public var temperature: Double = 1.0
    @Published public var coolingRate: Double = 0.95
    @Published public var minTemperature: Double = 0.01
    @Published public var springLength: Double = 100.0
    @Published public var springConstant: Double = 0.5
    @Published public var repulsionStrength: Double = 500.0
    @Published public var damping: Double = 0.9
    
    // Simulation state
    @Published public private(set) var isRunning = false
    @Published public private(set) var iteration = 0
    @Published public private(set) var maxIterations = 200
    
    private let deltaTime: Double = 1.0/60.0 // 60 FPS target
    private var spatialGrid: SpatialGrid?
    
    public init() {}
    
    /// Initialize node positions randomly within canvas bounds
    public func initializePositions(nodes: inout [NetworkNode], canvasSize: CGSize) {
        let margin = 50.0
        let width = canvasSize.width - 2 * margin
        let height = canvasSize.height - 2 * margin
        
        for i in 0..<nodes.count {
            let x = margin + Double.random(in: 0...1) * width
            let y = margin + Double.random(in: 0...1) * height
            nodes[i].updatePosition(CGPoint(x: x, y: y))
            nodes[i].updateVelocity(.zero)
        }
        
        // Initialize spatial grid for optimization
        spatialGrid = SpatialGrid(bounds: CGRect(origin: .zero, size: canvasSize), cellSize: 100)
        
        reset()
    }
    
    /// Reset simulation parameters
    public func reset() {
        temperature = 1.0
        iteration = 0
        isRunning = true
    }
    
    /// Perform one simulation step
    public func step(nodes: inout [NetworkNode], canvasSize: CGSize) {
        guard isRunning && iteration < maxIterations && temperature > minTemperature else {
            isRunning = false
            return
        }
        
        updateSpatialGrid(nodes: nodes)
        
        // Calculate forces for each node
        var forces = Array(repeating: CGPoint.zero, count: nodes.count)
        
        // Repulsive forces (all pairs)
        calculateRepulsiveForces(nodes: nodes, forces: &forces)
        
        // Attractive forces (connected nodes only)
        // Note: We would need edge information here, skipping for now as edges are managed separately
        
        // Apply forces and update positions
        applyForces(nodes: &nodes, forces: forces, canvasSize: canvasSize)
        
        // Cool the system
        temperature *= coolingRate
        iteration += 1
        
        if temperature <= minTemperature || iteration >= maxIterations {
            isRunning = false
        }
    }
    
    /// Step with edges for attractive forces
    public func step(nodes: inout [NetworkNode], edges: [NetworkEdge], canvasSize: CGSize) {
        guard isRunning && iteration < maxIterations && temperature > minTemperature else {
            isRunning = false
            return
        }
        
        updateSpatialGrid(nodes: nodes)
        
        var forces = Array(repeating: CGPoint.zero, count: nodes.count)
        
        // Repulsive forces
        calculateRepulsiveForces(nodes: nodes, forces: &forces)
        
        // Attractive forces from edges
        calculateAttractiveForces(nodes: nodes, edges: edges, forces: &forces)
        
        // Apply forces
        applyForces(nodes: &nodes, forces: forces, canvasSize: canvasSize)
        
        // Cool the system
        temperature *= coolingRate
        iteration += 1
        
        if temperature <= minTemperature || iteration >= maxIterations {
            isRunning = false
        }
    }
    
    private func updateSpatialGrid(nodes: [NetworkNode]) {
        spatialGrid?.clear()
        for (index, node) in nodes.enumerated() {
            spatialGrid?.insert(nodeIndex: index, position: node.position)
        }
    }
    
    private func calculateRepulsiveForces(nodes: [NetworkNode], forces: inout [CGPoint]) {
        for i in 0..<nodes.count {
            let nodeA = nodes[i]
            
            // Use spatial grid for optimization if available
            let nearbyNodes = spatialGrid?.getNearbyNodes(around: nodeA.position, radius: repulsionStrength * 2) ?? Array(0..<nodes.count)
            
            for j in nearbyNodes {
                if i == j { continue }
                
                let nodeB = nodes[j]
                let dx = nodeA.position.x - nodeB.position.x
                let dy = nodeA.position.y - nodeB.position.y
                let distance = sqrt(dx * dx + dy * dy)
                
                if distance > 0 && distance < repulsionStrength * 2 {
                    let force = repulsionStrength / max(1.0, distance * distance)
                    let normalizedDx = dx / distance
                    let normalizedDy = dy / distance
                    
                    forces[i].x += normalizedDx * force
                    forces[i].y += normalizedDy * force
                }
            }
        }
    }
    
    private func calculateAttractiveForces(nodes: [NetworkNode], edges: [NetworkEdge], forces: inout [CGPoint]) {
        // Create node index lookup
        var nodeIndices: [ComponentIdentifier: Int] = [:]
        for (index, node) in nodes.enumerated() {
            nodeIndices[node.id] = index
        }
        
        for edge in edges {
            guard let sourceIndex = nodeIndices[edge.source],
                  let targetIndex = nodeIndices[edge.target] else {
                continue
            }
            
            let sourceNode = nodes[sourceIndex]
            let targetNode = nodes[targetIndex]
            
            let dx = targetNode.position.x - sourceNode.position.x
            let dy = targetNode.position.y - sourceNode.position.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance > 0 {
                // Spring force proportional to distance from ideal length
                let displacement = distance - springLength
                let force = springConstant * displacement * abs(edge.strength)
                
                let normalizedDx = dx / distance
                let normalizedDy = dy / distance
                
                // Apply equal and opposite forces
                forces[sourceIndex].x += normalizedDx * force
                forces[sourceIndex].y += normalizedDy * force
                forces[targetIndex].x -= normalizedDx * force
                forces[targetIndex].y -= normalizedDy * force
            }
        }
    }
    
    private func applyForces(nodes: inout [NetworkNode], forces: [CGPoint], canvasSize: CGSize) {
        let margin = 20.0
        
        for i in 0..<nodes.count {
            var velocity = nodes[i].velocity
            
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
            var newPosition = nodes[i].position
            newPosition.x += velocity.x * deltaTime
            newPosition.y += velocity.y * deltaTime
            
            // Keep nodes within canvas bounds
            newPosition.x = max(margin, min(canvasSize.width - margin, newPosition.x))
            newPosition.y = max(margin, min(canvasSize.height - margin, newPosition.y))
            
            nodes[i].updatePosition(newPosition)
            nodes[i].updateVelocity(velocity)
        }
    }
    
    /// Manually stop the simulation
    public func stop() {
        isRunning = false
    }
    
    /// Check if simulation has converged
    public var hasConverged: Bool {
        return !isRunning || temperature <= minTemperature
    }
    
    /// Get progress percentage
    public var progress: Double {
        return Double(iteration) / Double(maxIterations)
    }
    
    /// Initialize positions working with CorrelationNetworkProcessor
    public func initializePositionsWithProcessor(processor: CorrelationNetworkProcessor, canvasSize: CGSize) {
        let margin = 50.0
        let width = canvasSize.width - 2 * margin
        let height = canvasSize.height - 2 * margin
        
        // We need to work around the immutable networkNodes by calling a method on processor
        processor.initializeNodePositions(canvasSize: canvasSize)
        
        // Initialize spatial grid for optimization
        spatialGrid = SpatialGrid(bounds: CGRect(origin: .zero, size: canvasSize), cellSize: 100)
        
        reset()
    }
    
    /// Step simulation working with CorrelationNetworkProcessor
    public func stepWithProcessor(processor: CorrelationNetworkProcessor, canvasSize: CGSize) {
        guard isRunning && iteration < maxIterations && temperature > minTemperature else {
            isRunning = false
            return
        }
        
        // Ask processor to perform physics step
        processor.performPhysicsStep(
            temperature: temperature,
            deltaTime: deltaTime,
            repulsionStrength: repulsionStrength,
            springLength: springLength,
            springConstant: springConstant,
            damping: damping,
            canvasSize: canvasSize
        )
        
        // Cool the system
        temperature *= coolingRate
        iteration += 1
        
        if temperature <= minTemperature || iteration >= maxIterations {
            isRunning = false
        }
    }
}

// MARK: - Spatial Grid for Performance Optimization

private class SpatialGrid {
    private let bounds: CGRect
    private let cellSize: Double
    private let cols: Int
    private let rows: Int
    private var grid: [[Int]]
    
    init(bounds: CGRect, cellSize: Double) {
        self.bounds = bounds
        self.cellSize = cellSize
        self.cols = Int(ceil(bounds.width / cellSize))
        self.rows = Int(ceil(bounds.height / cellSize))
        self.grid = Array(repeating: Array(repeating: Int(), count: 0), count: cols * rows)
    }
    
    func clear() {
        for i in 0..<grid.count {
            grid[i].removeAll(keepingCapacity: true)
        }
    }
    
    func insert(nodeIndex: Int, position: CGPoint) {
        let col = Int((position.x - bounds.minX) / cellSize)
        let row = Int((position.y - bounds.minY) / cellSize)
        
        if col >= 0 && col < cols && row >= 0 && row < rows {
            let index = row * cols + col
            if index < grid.count {
                grid[index].append(nodeIndex)
            }
        }
    }
    
    func getNearbyNodes(around position: CGPoint, radius: Double) -> [Int] {
        let cellRadius = Int(ceil(radius / cellSize))
        let centerCol = Int((position.x - bounds.minX) / cellSize)
        let centerRow = Int((position.y - bounds.minY) / cellSize)
        
        var nearbyNodes: [Int] = []
        
        for row in max(0, centerRow - cellRadius)...min(rows - 1, centerRow + cellRadius) {
            for col in max(0, centerCol - cellRadius)...min(cols - 1, centerCol + cellRadius) {
                let index = row * cols + col
                if index < grid.count {
                    nearbyNodes.append(contentsOf: grid[index])
                }
            }
        }
        
        return nearbyNodes
    }
}