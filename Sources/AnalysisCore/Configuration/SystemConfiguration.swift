import Foundation

/// SystemConfiguration manages all configurable parameters for the analysis system
/// This allows for hypothesis testing without code changes
public struct SystemConfiguration: Codable, Sendable {
    
    // MARK: - Correlation Analysis Parameters
    public struct CorrelationParameters: Codable, Sendable {
        /// Minimum correlation coefficient to consider significant
        public let minimumCorrelation: Double
        
        /// Strong correlation threshold
        public let strongCorrelationThreshold: Double
        
        /// Very strong correlation threshold
        public let veryStrongCorrelationThreshold: Double
        
        /// Minimum sample size for valid correlation
        public let minimumSampleSize: Int
        
        /// Confidence level for statistical significance (e.g., 0.95 for 95%)
        public let confidenceLevel: Double
        
        /// P-value threshold for significance
        public let pValueThreshold: Double
        
        /// Use Bonferroni correction for multiple comparisons
        public let useBonferroniCorrection: Bool
        
        public init(
            minimumCorrelation: Double = 0.3,
            strongCorrelationThreshold: Double = 0.7,
            veryStrongCorrelationThreshold: Double = 0.9,
            minimumSampleSize: Int = 30,
            confidenceLevel: Double = 0.95,
            pValueThreshold: Double = 0.05,
            useBonferroniCorrection: Bool = true
        ) {
            self.minimumCorrelation = minimumCorrelation
            self.strongCorrelationThreshold = strongCorrelationThreshold
            self.veryStrongCorrelationThreshold = veryStrongCorrelationThreshold
            self.minimumSampleSize = minimumSampleSize
            self.confidenceLevel = confidenceLevel
            self.pValueThreshold = pValueThreshold
            self.useBonferroniCorrection = useBonferroniCorrection
        }
    }
    
    // MARK: - Early Warning System Parameters
    public struct EarlyWarningParameters: Codable, Sendable {
        /// Risk threshold multiplier for critical warnings
        public let criticalRiskMultiplier: Double
        
        /// Percentiles to test for optimal thresholds
        public let thresholdPercentiles: [Int]
        
        /// Minimum F1 score for valid threshold
        public let minimumF1Score: Double
        
        /// Minimum students required for threshold calculation
        public let minimumStudentsForThreshold: Int
        
        /// Weight for false positives vs false negatives
        public let falsePositiveWeight: Double
        
        public init(
            criticalRiskMultiplier: Double = 0.8,
            thresholdPercentiles: [Int] = [10, 20, 25, 30, 35, 40, 45, 50, 60, 70],
            minimumF1Score: Double = 0.6,
            minimumStudentsForThreshold: Int = 50,
            falsePositiveWeight: Double = 1.0
        ) {
            self.criticalRiskMultiplier = criticalRiskMultiplier
            self.thresholdPercentiles = thresholdPercentiles
            self.minimumF1Score = minimumF1Score
            self.minimumStudentsForThreshold = minimumStudentsForThreshold
            self.falsePositiveWeight = falsePositiveWeight
        }
    }
    
    // MARK: - Student Growth Parameters
    public struct GrowthParameters: Codable, Sendable {
        /// Growth calculation method
        public enum GrowthMethod: String, Codable, Sendable {
            case simpleGain = "simple_gain"           // Current - Previous
            case percentGrowth = "percent_growth"     // (Current - Previous) / Previous
            case valueAdded = "value_added"            // Actual - Expected
            case studentGrowthPercentile = "sgp"      // Student Growth Percentile
            case conditionalGrowth = "conditional"    // Growth conditioned on initial score
        }
        
        /// Selected growth calculation method
        public let growthMethod: GrowthMethod
        
        /// Minimum growth to be considered adequate
        public let adequateGrowthThreshold: Double
        
        /// Expected growth per year (grade level)
        public let expectedAnnualGrowth: Double
        
        /// Use cohort-referenced growth (vs criterion-referenced)
        public let useCohortReferencing: Bool
        
        /// Include confidence intervals in growth calculations
        public let includeConfidenceIntervals: Bool
        
        /// Account for regression to the mean
        public let adjustForRegressionToMean: Bool
        
        /// Growth percentile thresholds
        public struct GrowthPercentiles: Codable, Sendable {
            public let low: Int       // Below this percentile = low growth
            public let typical: Int    // Below this percentile = typical growth  
            public let high: Int       // At or above this percentile = high growth
            
            public init(low: Int = 35, typical: Int = 65, high: Int = 65) {
                self.low = low
                self.typical = typical
                self.high = high
            }
        }
        
        public let growthPercentiles: GrowthPercentiles
        
        public init(
            growthMethod: GrowthMethod = .valueAdded,
            adequateGrowthThreshold: Double = 1.0,
            expectedAnnualGrowth: Double = 1.0,
            useCohortReferencing: Bool = true,
            includeConfidenceIntervals: Bool = true,
            adjustForRegressionToMean: Bool = true,
            growthPercentiles: GrowthPercentiles = GrowthPercentiles()
        ) {
            self.growthMethod = growthMethod
            self.adequateGrowthThreshold = adequateGrowthThreshold
            self.expectedAnnualGrowth = expectedAnnualGrowth
            self.useCohortReferencing = useCohortReferencing
            self.includeConfidenceIntervals = includeConfidenceIntervals
            self.adjustForRegressionToMean = adjustForRegressionToMean
            self.growthPercentiles = growthPercentiles
        }
    }
    
    // MARK: - ILP Generation Parameters
    public struct ILPParameters: Codable, Sendable {
        /// Score threshold for enrichment vs remediation
        public let enrichmentThreshold: Double
        
        /// Proficiency level thresholds
        public struct ProficiencyThresholds: Codable, Sendable {
            public let minimal: Double
            public let basic: Double
            public let proficient: Double
            public let advanced: Double
            
            public init(
                minimal: Double = 25.0,
                basic: Double = 40.0,
                proficient: Double = 60.0,
                advanced: Double = 85.0
            ) {
                self.minimal = minimal
                self.basic = basic
                self.proficient = proficient
                self.advanced = advanced
            }
        }
        
        public let proficiencyThresholds: ProficiencyThresholds
        
        /// Maximum standards to include in ILP
        public let maxStandardsPerILP: Int
        
        /// Weight for correlation strength in ILP generation
        public let correlationWeight: Double
        
        /// Include prerequisite standards
        public let includePrerequisites: Bool
        
        /// Include cross-curricular standards
        public let includeCrossCurricular: Bool
        
        public init(
            enrichmentThreshold: Double = 85.0,
            proficiencyThresholds: ProficiencyThresholds = ProficiencyThresholds(),
            maxStandardsPerILP: Int = 10,
            correlationWeight: Double = 0.7,
            includePrerequisites: Bool = true,
            includeCrossCurricular: Bool = true
        ) {
            self.enrichmentThreshold = enrichmentThreshold
            self.proficiencyThresholds = proficiencyThresholds
            self.maxStandardsPerILP = maxStandardsPerILP
            self.correlationWeight = correlationWeight
            self.includePrerequisites = includePrerequisites
            self.includeCrossCurricular = includeCrossCurricular
        }
    }
    
    // MARK: - Performance Parameters
    public struct PerformanceParameters: Codable, Sendable {
        /// Batch size for processing
        public let batchSize: Int
        
        /// Enable parallel processing
        public let enableParallelProcessing: Bool
        
        /// Maximum concurrent tasks
        public let maxConcurrentTasks: Int
        
        /// Memory limit in MB
        public let memoryLimitMB: Int
        
        /// Enable MLX acceleration
        public let enableMLXAcceleration: Bool
        
        public init(
            batchSize: Int = 1000,
            enableParallelProcessing: Bool = true,
            maxConcurrentTasks: Int = 8,
            memoryLimitMB: Int = 4096,
            enableMLXAcceleration: Bool = true
        ) {
            self.batchSize = batchSize
            self.enableParallelProcessing = enableParallelProcessing
            self.maxConcurrentTasks = maxConcurrentTasks
            self.memoryLimitMB = memoryLimitMB
            self.enableMLXAcceleration = enableMLXAcceleration
        }
    }
    
    // MARK: - Validation Parameters
    public struct ValidationParameters: Codable, Sendable {
        /// Cross-validation folds
        public let crossValidationFolds: Int
        
        /// Train/test split ratio
        public let trainTestSplitRatio: Double
        
        /// Use stratified sampling
        public let useStratifiedSampling: Bool
        
        /// Minimum confidence for predictions
        public let minimumPredictionConfidence: Double
        
        public init(
            crossValidationFolds: Int = 5,
            trainTestSplitRatio: Double = 0.8,
            useStratifiedSampling: Bool = true,
            minimumPredictionConfidence: Double = 0.7
        ) {
            self.crossValidationFolds = crossValidationFolds
            self.trainTestSplitRatio = trainTestSplitRatio
            self.useStratifiedSampling = useStratifiedSampling
            self.minimumPredictionConfidence = minimumPredictionConfidence
        }
    }
    
    // MARK: - Main Configuration
    public let correlation: CorrelationParameters
    public let earlyWarning: EarlyWarningParameters
    public let growth: GrowthParameters
    public let ilp: ILPParameters
    public let performance: PerformanceParameters
    public let validation: ValidationParameters
    
    /// Metadata about configuration
    public struct Metadata: Codable, Sendable {
        public let version: String
        public let lastModified: Date
        public let description: String?
        
        public init(
            version: String = "1.0.0",
            lastModified: Date = Date(),
            description: String? = nil
        ) {
            self.version = version
            self.lastModified = lastModified
            self.description = description
        }
    }
    
    public let metadata: Metadata
    
    // MARK: - Initialization
    public init(
        correlation: CorrelationParameters = CorrelationParameters(),
        earlyWarning: EarlyWarningParameters = EarlyWarningParameters(),
        growth: GrowthParameters = GrowthParameters(),
        ilp: ILPParameters = ILPParameters(),
        performance: PerformanceParameters = PerformanceParameters(),
        validation: ValidationParameters = ValidationParameters(),
        metadata: Metadata = Metadata()
    ) {
        self.correlation = correlation
        self.earlyWarning = earlyWarning
        self.growth = growth
        self.ilp = ilp
        self.performance = performance
        self.validation = validation
        self.metadata = metadata
    }
    
    // MARK: - Default Configuration
    public static let `default` = SystemConfiguration()
}

// MARK: - Configuration Manager
public actor ConfigurationManager {
    private var currentConfiguration: SystemConfiguration
    private let configurationPath: URL
    
    public init(configurationPath: URL? = nil) {
        self.configurationPath = configurationPath ?? Self.defaultConfigurationPath
        self.currentConfiguration = SystemConfiguration.default
    }
    
    private static var defaultConfigurationPath: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("StudentAnalysisSystem/configuration.json")
    }
    
    /// Load configuration from file
    public func loadConfiguration() async throws {
        guard FileManager.default.fileExists(atPath: configurationPath.path) else {
            print("Configuration file not found at \(configurationPath.path). Using defaults.")
            return
        }
        
        let data = try Data(contentsOf: configurationPath)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        currentConfiguration = try decoder.decode(SystemConfiguration.self, from: data)
        print("Configuration loaded from \(configurationPath.path)")
    }
    
    /// Save current configuration to file
    public func saveConfiguration() async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(currentConfiguration)
        
        // Create directory if it doesn't exist
        let directory = configurationPath.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        try data.write(to: configurationPath)
        print("Configuration saved to \(configurationPath.path)")
    }
    
    /// Get current configuration
    public func getConfiguration() -> SystemConfiguration {
        return currentConfiguration
    }
    
    /// Update configuration
    public func updateConfiguration(_ configuration: SystemConfiguration) async throws {
        currentConfiguration = configuration
        try await saveConfiguration()
    }
    
    /// Reset to default configuration
    public func resetToDefault() async throws {
        currentConfiguration = SystemConfiguration.default
        try await saveConfiguration()
    }
}