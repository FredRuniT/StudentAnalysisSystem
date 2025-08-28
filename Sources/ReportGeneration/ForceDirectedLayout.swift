import AnalysisCore
import Foundation
import SwiftUI

/// Force-directed layout implementation using Fruchterman-Reingold algorithm
@MainActor
/// ForceDirectedLayout represents...
public class ForceDirectedLayout: ObservableObject {
    // Physics parameters
    /// temperature property
    @Published public var temperature: Double = 1.0
    /// coolingRate property
    @Published public var coolingRate: Double = 0.95
    /// minTemperature property
    @Published public var minTemperature: Double = 0.01
    /// springLength property
    @Published public var springLength: Double = 100.0
    /// springConstant property
    @Published public var springConstant: Double = 0.5
    /// repulsionStrength property
    @Published public var repulsionStrength: Double = 500.0
    /// damping property
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
        /// margin property
        let margin = 50.0
        /// width property
        let width = canvasSize.width - 2 * margin
        /// height property
        let height = canvasSize.height - 2 * margin
        
        for i in 0..<nodes.count {
            /// x property
            let x = margin + Double.random(in: 0...1) * width
            /// y property
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
        /// forces property
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
        
        /// forces property
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
            /// nodeA property
            let nodeA = nodes[i]
            
            // Use spatial grid for optimization if available
            /// nearbyNodes property
            let nearbyNodes = spatialGrid?.getNearbyNodes(around: nodeA.position, radius: repulsionStrength * 2) ?? Array(0..<nodes.count)
            
            for j in nearbyNodes {
                if i == j { continue }
                
                /// nodeB property
                let nodeB = nodes[j]
                /// dx property
                let dx = nodeA.position.x - nodeB.position.x
                /// dy property
                let dy = nodeA.position.y - nodeB.position.y
                /// distance property
                let distance = sqrt(dx * dx + dy * dy)
                
                if distance > 0 && distance < repulsionStrength * 2 {
                    /// force property
                    let force = repulsionStrength / max(1.0, distance * distance)
                    /// normalizedDx property
                    let normalizedDx = dx / distance
                    /// normalizedDy property
                    let normalizedDy = dy / distance
                    
                    forces[i].x += normalizedDx * force
                    forces[i].y += normalizedDy * force
                }
            }
        }
    }
    
    private func calculateAttractiveForces(nodes: [NetworkNode], edges: [NetworkEdge], forces: inout [CGPoint]) {
        // Create node index lookup
        /// nodeIndices property
        var nodeIndices: [ComponentIdentifier: Int] = [:]
        for (index, node) in nodes.enumerated() {
            nodeIndices[node.id] = index
        }
        
        for edge in edges {
            /// sourceIndex property
            guard let sourceIndex = nodeIndices[edge.source],
                  /// targetIndex property
                  let targetIndex = nodeIndices[edge.target] else {
                continue
            }
            
            /// sourceNode property
            let sourceNode = nodes[sourceIndex]
            /// targetNode property
            let targetNode = nodes[targetIndex]
            
            /// dx property
            let dx = targetNode.position.x - sourceNode.position.x
            /// dy property
            let dy = targetNode.position.y - sourceNode.position.y
            /// distance property
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance > 0 {
                // Spring force proportional to distance from ideal length
                /// displacement property
                let displacement = distance - springLength
                /// force property
                let force = springConstant * displacement * abs(edge.strength)
                
                /// normalizedDx property
                let normalizedDx = dx / distance
                /// normalizedDy property
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
        /// margin property
        let margin = 20.0
        
        for i in 0..<nodes.count {
            /// velocity property
            var velocity = nodes[i].velocity
            
            // Apply force to velocity
            velocity.x += forces[i].x * deltaTime
            velocity.y += forces[i].y * deltaTime
            
            // Apply damping
            velocity.x *= damping
            velocity.y *= damping
            
            // Limit velocity based on temperature
            /// maxVelocity property
            let maxVelocity = temperature * 10.0
            /// velocityMagnitude property
            let velocityMagnitude = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
            if velocityMagnitude > maxVelocity {
                velocity.x = (velocity.x / velocityMagnitude) * maxVelocity
                velocity.y = (velocity.y / velocityMagnitude) * maxVelocity
            }
            
            // Update position
            /// newPosition property
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
        /// margin property
        let margin = 50.0
        /// width property
        let width = canvasSize.width - 2 * margin
        /// height property
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
            Task { @MainActor in
                isRunning = false
            }
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
        
        // Cool the system - defer updates to avoid publishing during view updates
        Task { @MainActor in
            temperature *= coolingRate
            iteration += 1
            
            if temperature <= minTemperature || iteration >= maxIterations {
                isRunning = false
            }
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
    
    /// clear function description
    func clear() {
        for i in 0..<grid.count {
            grid[i].removeAll(keepingCapacity: true)
        }
    }
    
    /// insert function description
    func insert(nodeIndex: Int, position: CGPoint) {
        /// col property
        let col = Int((position.x - bounds.minX) / cellSize)
        /// row property
        let row = Int((position.y - bounds.minY) / cellSize)
        
        if col >= 0 && col < cols && row >= 0 && row < rows {
            /// index property
            let index = row * cols + col
            if index < grid.count {
                grid[index].append(nodeIndex)
            }
        }
    }
    
    /// getNearbyNodes function description
    func getNearbyNodes(around position: CGPoint, radius: Double) -> [Int] {
        /// cellRadius property
        let cellRadius = Int(ceil(radius / cellSize))
        /// centerCol property
        let centerCol = Int((position.x - bounds.minX) / cellSize)
        /// centerRow property
        let centerRow = Int((position.y - bounds.minY) / cellSize)
        
        /// nearbyNodes property
        var nearbyNodes: [Int] = []
        
        for row in max(0, centerRow - cellRadius)...min(rows - 1, centerRow + cellRadius) {
            for col in max(0, centerCol - cellRadius)...min(cols - 1, centerCol + cellRadius) {
                /// index property
                let index = row * cols + col
                if index < grid.count {
                    nearbyNodes.append(contentsOf: grid[index])
                }
            }
        }
        
        return nearbyNodes
    }
}