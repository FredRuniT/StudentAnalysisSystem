import Foundation
import MLX

public actor MLXAccelerator {
    private let deviceType: MLX.Device
    
    public init(preferredDevice: MLX.Device = .gpu) {
        self.deviceType = preferredDevice
    }
    
    public func calculateStatistics(for values: [Double]) async -> (mean: Double, std: Double, min: Double, max: Double, median: Double) {
        guard !values.isEmpty else {
            return (0, 0, 0, 0, 0)
        }
        
        // Use standard Swift calculations for now
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let std = sqrt(variance)
        let min = values.min() ?? 0
        let max = values.max() ?? 0
        let sorted = values.sorted()
        let median = sorted[sorted.count / 2]
        
        return (mean, std, min, max, median)
    }
    
    public func correlationMatrix(for data: [[Double]]) async -> [[Double]] {
        guard !data.isEmpty else { return [] }
        
        let n = data.count
        var matrix = Array(repeating: Array(repeating: 0.0, count: n), count: n)
        
        for i in 0..<n {
            for j in 0..<n {
                matrix[i][j] = calculateCorrelation(data[i], data[j])
            }
        }
        
        return matrix
    }
    
    public func percentileThresholds(for values: [Double], percentiles: [Double]) async -> [Double: Double] {
        guard !values.isEmpty else { return [:] }
        
        let sorted = values.sorted()
        var thresholds: [Double: Double] = [:]
        
        for p in percentiles {
            let index = Int((p / 100.0) * Double(sorted.count - 1))
            thresholds[p] = sorted[index]
        }
        
        return thresholds
    }
    
    public func normalizeScores(_ scores: [Double], method: NormalizationMethod) async -> [Double] {
        guard !scores.isEmpty else { return [] }
        
        switch method {
        case .zScore:
            let mean = scores.reduce(0, +) / Double(scores.count)
            let variance = scores.map { pow($0 - mean, 2) }.reduce(0, +) / Double(scores.count)
            let std = sqrt(variance)
            return scores.map { ($0 - mean) / std }
            
        case .minMax:
            let min = scores.min() ?? 0
            let max = scores.max() ?? 1
            let range = max - min
            return scores.map { range == 0 ? 0.5 : ($0 - min) / range }
            
        case .percentile:
            let sorted = scores.sorted()
            return scores.map { score in
                let rank = sorted.firstIndex(of: score) ?? 0
                return Double(rank) / Double(scores.count)
            }
        }
    }
    
    private func calculateCorrelation(_ x: [Double], _ y: [Double]) -> Double {
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
}

public enum NormalizationMethod {
    case zScore
    case minMax
    case percentile
}