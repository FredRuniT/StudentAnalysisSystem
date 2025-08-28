import Foundation

public struct CorrelationResult: Sendable {
    public let source: ComponentPair
    public let target: ComponentPair
    public let pearsonR: Double
    public let spearmanR: Double
    public let rSquared: Double
    public let pValue: Double
    public let sampleSize: Int
    public let confidenceInterval: (lower: Double, upper: Double)
    public let isSignificant: Bool
    
    public init(
        source: ComponentPair,
        target: ComponentPair,
        pearsonR: Double,
        spearmanR: Double,
        rSquared: Double,
        pValue: Double,
        sampleSize: Int,
        confidenceInterval: (lower: Double, upper: Double),
        isSignificant: Bool
    ) {
        self.source = source
        self.target = target
        self.pearsonR = pearsonR
        self.spearmanR = spearmanR
        self.rSquared = rSquared
        self.pValue = pValue
        self.sampleSize = sampleSize
        self.confidenceInterval = confidenceInterval
        self.isSignificant = isSignificant
    }
    
    public var correlationStrength: CorrelationStrength {
        let absR = abs(pearsonR)
        switch absR {
        case 0.8...1.0: return .veryStrong
        case 0.6..<0.8: return .strong
        case 0.4..<0.6: return .moderate
        case 0.2..<0.4: return .weak
        default: return .negligible
        }
    }
    
    public enum CorrelationStrength: String, Sendable {
        case veryStrong = "Very Strong"
        case strong = "Strong"
        case moderate = "Moderate"
        case weak = "Weak"
        case negligible = "Negligible"
    }
    
    public var direction: CorrelationDirection {
        pearsonR > 0 ? .positive : .negative
    }
    
    public enum CorrelationDirection: String, Sendable {
        case positive = "Positive"
        case negative = "Negative"
    }
}

public struct CorrelationMatrix: Sendable {
    private var matrix: [[CorrelationResult?]]
    public let size: Int
    
    public init(size: Int) {
        self.size = size
        self.matrix = Array(repeating: Array(repeating: nil, count: size), count: size)
    }
    
    public subscript(row: Int, column: Int) -> CorrelationResult? {
        get { matrix[row][column] }
        set { matrix[row][column] = newValue }
    }
    
    public func getStrongestCorrelations(threshold: Double = 0.6) -> [CorrelationResult] {
        var strong: [CorrelationResult] = []
        for row in 0..<size {
            for col in (row+1)..<size {
                if let correlation = matrix[row][col],
                   abs(correlation.pearsonR) >= threshold {
                    strong.append(correlation)
                }
            }
        }
        return strong.sorted { abs($0.pearsonR) > abs($1.pearsonR) }
    }
}