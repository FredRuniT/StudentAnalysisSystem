import Foundation

public struct ComponentCorrelationMap: Sendable {
    public let sourceComponent: ComponentIdentifier
    public let correlations: [ComponentCorrelation]
    
    public init(sourceComponent: ComponentIdentifier, correlations: [ComponentCorrelation]) {
        self.sourceComponent = sourceComponent
        self.correlations = correlations
    }
}

public struct ComponentCorrelation: Sendable {
    public let target: ComponentIdentifier
    public let correlation: Double
    public let confidence: Double
    public let sampleSize: Int
    
    public init(target: ComponentIdentifier, correlation: Double, confidence: Double, sampleSize: Int) {
        self.target = target
        self.correlation = correlation
        self.confidence = confidence
        self.sampleSize = sampleSize
    }
}