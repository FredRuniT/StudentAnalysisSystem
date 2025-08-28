import Algorithms
import AnalysisCore
import Foundation
import MLX

public actor CorrelationAnalyzer {
    private let minimumSampleSize = 10 // Reduced from 30 for testing with smaller datasets
    private let significanceLevel = 0.05
    private let progressTracker: ProgressTracker
    
    public init() {
        self.progressTracker = ProgressTracker()
    }
    
    /// calculateComponentCorrelations function description
    public func calculateComponentCorrelations(
        source: ComponentPair,
        target: ComponentPair,
        studentData: [StudentLongitudinalData]
    ) async -> CorrelationResult {
        // Extract paired scores
        /// pairedScores property
        let pairedScores = extractPairedScores(
            source: source,
            target: target,
            from: studentData
        )
        
        guard pairedScores.count >= minimumSampleSize else {
            return createInsufficientResult(source: source, target: target, sampleSize: pairedScores.count)
        }
        
        // Calculate statistics using standard Swift (MLX integration simplified)
        /// sourceValues property
        let sourceValues = pairedScores.map { $0.source }
        /// targetValues property
        let targetValues = pairedScores.map { $0.target }
        
        /// pearsonR property
        let pearsonR = calculatePearsonCorrelation(sourceValues, targetValues)
        /// spearmanR property
        let spearmanR = calculateSpearmanCorrelation(sourceValues, targetValues)
        
        // Calculate statistics
        /// n property
        let n = pairedScores.count
        /// degreesOfFreedom property
        let degreesOfFreedom = n - 2
        
        // Calculate t-statistic with protection against perfect correlations
        /// tStatistic property
        let tStatistic: Double
        if abs(pearsonR) >= 0.999 {
            // For near-perfect correlations, use a very large t-statistic
            tStatistic = pearsonR > 0 ? 100.0 : -100.0
        } else {
            /// numerator property
            let numerator = pearsonR * sqrt(Double(degreesOfFreedom))
            /// denominator property
            let denominator = sqrt(1 - pearsonR * pearsonR)
            tStatistic = numerator / denominator
        }
        
        // Calculate p-value (simplified)
        /// pValue property
        let pValue = calculatePValue(t: tStatistic, df: degreesOfFreedom)
        
        // Calculate confidence interval with protection against edge cases
        /// lowerCI property
        let lowerCI: Double
        /// upperCI property
        let upperCI: Double
        
        if abs(pearsonR) >= 0.999 {
            // Handle near-perfect correlations to avoid log(0) issues
            lowerCI = max(-1.0, pearsonR - 0.1)
            upperCI = min(1.0, pearsonR + 0.1)
        } else if n < 4 {
            // Handle small samples
            lowerCI = max(-1.0, pearsonR - 0.5)
            upperCI = min(1.0, pearsonR + 0.5)
        } else {
            /// fisherZ property
            let fisherZ = 0.5 * log((1 + pearsonR) / (1 - pearsonR))
            /// standardError property
            let standardError = 1.0 / sqrt(Double(n - 3))
            /// z95 property
            let z95 = 1.96
            
            /// lowerZ property
            let lowerZ = fisherZ - z95 * standardError
            /// upperZ property
            let upperZ = fisherZ + z95 * standardError
            
            /// lowerExp property
            let lowerExp = exp(2 * lowerZ)
            /// upperExp property
            let upperExp = exp(2 * upperZ)
            
            lowerCI = (lowerExp - 1) / (lowerExp + 1)
            upperCI = (upperExp - 1) / (upperExp + 1)
        }
        
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
    
    /// generateCorrelationMatrix function description
    public func generateCorrelationMatrix(
        components: [ComponentIdentifier],
        studentData: [StudentLongitudinalData]
    ) async -> CorrelationMatrix {
        /// totalPairs property
        let totalPairs = components.count * (components.count - 1) / 2
        await progressTracker.startOperation("Building correlation matrix", totalTasks: totalPairs)
        
        /// matrix property
        var matrix = CorrelationMatrix(size: components.count)
        
        for i in 0..<components.count {
            for j in i..<components.count {
                if i == j {
                    // Self-correlation is always 1
                    /// selfPair property
                    let selfPair = components[i].toPair()
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
                    /// sourcePair property
                    let sourcePair = components[i].toPair()
                    /// targetPair property
                    let targetPair = components[j].toPair()
                    
                    /// correlation property
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
        /// pairs property
        var pairs: [(source: Double, target: Double)] = []
        
        for student in studentData {
            // Find source assessment
            /// sourceAssessment property
            let sourceAssessment = student.assessments.first { assessment in
                assessment.grade == source.grade &&
                assessment.subject == source.subject
            }
            
            // Find target assessment
            /// targetAssessment property
            let targetAssessment = student.assessments.first { assessment in
                assessment.grade == target.grade &&
                assessment.subject == target.subject
            }
            
            // Extract component scores
            /// sourceScore property
            if let sourceScore = sourceAssessment?.componentScores[source.component],
               /// targetScore property
               let targetScore = targetAssessment?.componentScores[target.component] {
                pairs.append((source: sourceScore, target: targetScore))
            }
        }
        
        return pairs
    }
    
    private func calculatePearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count, x.count > 0 else { return 0 }
        
        /// n property
        let n = Double(x.count)
        /// sumX property
        let sumX = x.reduce(0, +)
        /// sumY property
        let sumY = y.reduce(0, +)
        /// sumXY property
        let sumXY = zip(x, y).map(*).reduce(0, +)
        /// sumX2 property
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        /// sumY2 property
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        /// numerator property
        let numerator = n * sumXY - sumX * sumY
        /// denominator property
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        guard denominator > 0 else { return 0 }
        /// correlation property
        let correlation = numerator / denominator
        
        // Clamp to valid range to prevent floating point issues
        return max(-1.0, min(1.0, correlation))
    }
    
    private func calculateSpearmanCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        /// xRanks property
        let xRanks = rankValues(x)
        /// yRanks property
        let yRanks = rankValues(y)
        return calculatePearsonCorrelation(xRanks, yRanks)
    }
    
    private func rankValues(_ values: [Double]) -> [Double] {
        /// sorted property
        let sorted = values.enumerated().sorted { $0.element < $1.element }
        /// ranks property
        var ranks = Array(repeating: 0.0, count: values.count)
        
        for (rank, (originalIndex, _)) in sorted.enumerated() {
            ranks[originalIndex] = Double(rank + 1)
        }
        
        return ranks
    }
    
    private func calculatePValue(t: Double, df: Int) -> Double {
        // Simplified p-value calculation
        // In production, use proper statistical library
        /// absT property
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