import Foundation
import MLX
import Algorithms
import AnalysisCore

public actor CorrelationAnalyzer {
    private let minimumSampleSize = 30
    private let significanceLevel = 0.05
    private let progressTracker: ProgressTracker
    
    public init() {
        self.progressTracker = ProgressTracker()
    }
    
    public func calculateComponentCorrelations(
        source: ComponentPair,
        target: ComponentPair,
        studentData: [StudentLongitudinalData]
    ) async -> CorrelationResult {
        // Extract paired scores
        let pairedScores = extractPairedScores(
            source: source,
            target: target,
            from: studentData
        )
        
        guard pairedScores.count >= minimumSampleSize else {
            return createInsufficientResult(source: source, target: target, sampleSize: pairedScores.count)
        }
        
        // Calculate statistics using standard Swift (MLX integration simplified)
        let sourceValues = pairedScores.map { $0.source }
        let targetValues = pairedScores.map { $0.target }
        
        let pearsonR = calculatePearsonCorrelation(sourceValues, targetValues)
        let spearmanR = calculateSpearmanCorrelation(sourceValues, targetValues)
        
        // Calculate statistics
        let n = pairedScores.count
        let tStatistic = pearsonR * sqrt(Double(n - 2)) / sqrt(1 - pearsonR * pearsonR)
        let degreesOfFreedom = n - 2
        
        // Calculate p-value (simplified)
        let pValue = calculatePValue(t: tStatistic, df: degreesOfFreedom)
        
        // Calculate confidence interval
        let fisherZ = 0.5 * log((1 + pearsonR) / (1 - pearsonR))
        let standardError = 1.0 / sqrt(Double(n - 3))
        let z95 = 1.96
        
        let lowerZ = fisherZ - z95 * standardError
        let upperZ = fisherZ + z95 * standardError
        
        let lowerCI = (exp(2 * lowerZ) - 1) / (exp(2 * lowerZ) + 1)
        let upperCI = (exp(2 * upperZ) - 1) / (exp(2 * upperZ) + 1)
        
        return CorrelationResult(
            source: source,
            target: target,
            pearsonR: pearsonR,
            spearmanR: spearmanR,
            rSquared: pearsonR * pearsonR,
            pValue: pValue,
            sampleSize: n,
            confidenceInterval: (lower: lowerCI, upper: upperCI),
            isSignificant: pValue < significanceLevel
        )
    }
    
    public func generateCorrelationMatrix(
        components: [ComponentIdentifier],
        studentData: [StudentLongitudinalData]
    ) async -> CorrelationMatrix {
        let totalPairs = components.count * (components.count - 1) / 2
        await progressTracker.startOperation("Building correlation matrix", totalTasks: totalPairs)
        
        var matrix = CorrelationMatrix(size: components.count)
        
        for i in 0..<components.count {
            for j in i..<components.count {
                if i == j {
                    // Self-correlation is always 1
                    let selfPair = ComponentPair(source: components[i], target: components[i])
                    matrix[i, j] = CorrelationResult(
                        source: selfPair,
                        target: selfPair,
                        pearsonR: 1.0,
                        spearmanR: 1.0,
                        rSquared: 1.0,
                        pValue: 0.0,
                        sampleSize: studentData.count,
                        confidenceInterval: (lower: 1.0, upper: 1.0),
                        isSignificant: true
                    )
                } else {
                    let sourcePair = ComponentPair(source: components[i], target: components[i])
                    let targetPair = ComponentPair(source: components[j], target: components[j])
                    
                    let correlation = await calculateComponentCorrelations(
                        source: sourcePair,
                        target: targetPair,
                        studentData: studentData
                    )
                    
                    matrix[i, j] = correlation
                    matrix[j, i] = correlation // Symmetric
                }
                await progressTracker.incrementProgress()
            }
        }
        
        await progressTracker.completeOperation()
        return matrix
    }
    
    private func extractPairedScores(
        source: ComponentPair,
        target: ComponentPair,
        from studentData: [StudentLongitudinalData]
    ) -> [(source: Double, target: Double)] {
        var pairs: [(source: Double, target: Double)] = []
        
        for student in studentData {
            // Find source assessment
            let sourceAssessment = student.assessments.first { assessment in
                assessment.grade == source.source.grade &&
                assessment.subject == source.source.subject
            }
            
            // Find target assessment
            let targetAssessment = student.assessments.first { assessment in
                assessment.grade == target.target.grade &&
                assessment.subject == target.target.subject
            }
            
            // Extract component scores
            if let sourceScore = sourceAssessment?.componentScores[source.source.component],
               let targetScore = targetAssessment?.componentScores[target.target.component] {
                pairs.append((source: sourceScore, target: targetScore))
            }
        }
        
        return pairs
    }
    
    private func calculatePearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count, x.count > 0 else { return 0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        return denominator == 0 ? 0 : numerator / denominator
    }
    
    private func calculateSpearmanCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        let xRanks = rankValues(x)
        let yRanks = rankValues(y)
        return calculatePearsonCorrelation(xRanks, yRanks)
    }
    
    private func rankValues(_ values: [Double]) -> [Double] {
        let sorted = values.enumerated().sorted { $0.element < $1.element }
        var ranks = Array(repeating: 0.0, count: values.count)
        
        for (rank, (originalIndex, _)) in sorted.enumerated() {
            ranks[originalIndex] = Double(rank + 1)
        }
        
        return ranks
    }
    
    private func calculatePValue(t: Double, df: Int) -> Double {
        // Simplified p-value calculation
        // In production, use proper statistical library
        let absT = abs(t)
        if absT < 1.0 { return 0.5 }
        if absT < 2.0 { return 0.05 }
        if absT < 2.5 { return 0.01 }
        if absT < 3.0 { return 0.005 }
        return 0.001
    }
    
    private func createInsufficientResult(source: ComponentPair, target: ComponentPair, sampleSize: Int) -> CorrelationResult {
        CorrelationResult(
            source: source,
            target: target,
            pearsonR: 0,
            spearmanR: 0,
            rSquared: 0,
            pValue: 1.0,
            sampleSize: sampleSize,
            confidenceInterval: (lower: 0, upper: 0),
            isSignificant: false
        )
    }
}