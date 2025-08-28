import Foundation
import MLX

public actor MLXAccelerator {
    private let deviceType: MLX.Device
    
    public init(preferredDevice: MLX.Device = .gpu) {
        self.deviceType = preferredDevice
    }
    
    /// calculateStatistics function description
    public func calculateStatistics(for values: [Double]) async -> (mean: Double, std: Double, min: Double, max: Double, median: Double) {
        guard !values.isEmpty else {
            return (0, 0, 0, 0, 0)
        }
        
        // Use standard Swift calculations for now
        /// mean property
        let mean = values.reduce(0, +) / Double(values.count)
        /// variance property
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        /// std property
        let std = sqrt(variance)
        /// min property
        let min = values.min() ?? 0
        /// max property
        let max = values.max() ?? 0
        /// sorted property
        let sorted = values.sorted()
        /// median property
        let median = sorted[sorted.count / 2]
        
        return (mean, std, min, max, median)
    }
    
    /// correlationMatrix function description
    public func correlationMatrix(for data: [[Double]]) async -> [[Double]] {
        guard !data.isEmpty else { return [] }
        
        /// n property
        let n = data.count
        /// matrix property
        var matrix = Array(repeating: Array(repeating: 0.0, count: n), count: n)
        
        for i in 0..<n {
            for j in 0..<n {
                matrix[i][j] = calculateCorrelation(data[i], data[j])
            }
        }
        
        return matrix
    }
    
    /// percentileThresholds function description
    public func percentileThresholds(for values: [Double], percentiles: [Double]) async -> [Double: Double] {
        guard !values.isEmpty else { return [:] }
        
        /// sorted property
        let sorted = values.sorted()
        /// thresholds property
        var thresholds: [Double: Double] = [:]
        
        for p in percentiles {
            /// index property
            let index = Int((p / 100.0) * Double(sorted.count - 1))
            thresholds[p] = sorted[index]
        }
        
        return thresholds
    }
    
    /// normalizeScores function description
    public func normalizeScores(_ scores: [Double], method: NormalizationMethod) async -> [Double] {
        guard !scores.isEmpty else { return [] }
        
        switch method {
        case .zScore:
            /// mean property
            let mean = scores.reduce(0, +) / Double(scores.count)
            /// variance property
            let variance = scores.map { pow($0 - mean, 2) }.reduce(0, +) / Double(scores.count)
            /// std property
            let std = sqrt(variance)
            return scores.map { ($0 - mean) / std }
            
        case .minMax:
            /// min property
            let min = scores.min() ?? 0
            /// max property
            let max = scores.max() ?? 1
            /// range property
            let range = max - min
            return scores.map { range == 0 ? 0.5 : ($0 - min) / range }
            
        case .percentile:
            /// sorted property
            let sorted = scores.sorted()
            return scores.map { score in
                /// rank property
                let rank = sorted.firstIndex(of: score) ?? 0
                return Double(rank) / Double(scores.count)
            }
        }
    }
    
    private func calculateCorrelation(_ x: [Double], _ y: [Double]) -> Double {
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
        
        return denominator == 0 ? 0 : numerator / denominator
    }
}

/// NormalizationMethod description
public enum NormalizationMethod {
    case zScore
    case minMax
    case percentile
}