import Foundation

/// ComponentCorrelationMap represents...
public struct ComponentCorrelationMap: Sendable, Codable {
    /// sourceComponent property
    public let sourceComponent: ComponentIdentifier
    /// correlations property
    public let correlations: [ComponentCorrelation]
    
    public init(sourceComponent: ComponentIdentifier, correlations: [ComponentCorrelation]) {
        self.sourceComponent = sourceComponent
        self.correlations = correlations
    }
}

/// ComponentCorrelation represents...
public struct ComponentCorrelation: Sendable, Codable {
    /// target property
    public let target: ComponentIdentifier
    /// correlation property
    public let correlation: Double
    /// confidence property
    public let confidence: Double
    /// sampleSize property
    public let sampleSize: Int
    
    public init(target: ComponentIdentifier, correlation: Double, confidence: Double, sampleSize: Int) {
        self.target = target
        self.correlation = correlation
        self.confidence = confidence
        self.sampleSize = sampleSize
    }
}