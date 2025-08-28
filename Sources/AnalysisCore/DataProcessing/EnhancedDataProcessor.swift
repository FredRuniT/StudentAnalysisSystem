import Algorithms
import CSV
import Foundation
import SwiftyJSON

/// Enhanced data processor using swift-algorithms and SwiftyJSON
public actor EnhancedDataProcessor {
    private let progressTracker: ProgressTracker
    
    public init() {
        self.progressTracker = ProgressTracker()
    }
    
    /// Process assessment data with advanced algorithms
    public func processWithAlgorithms(
        _ data: OptimizedDataFrame
    ) async -> ProcessedAssessmentData {
        await progressTracker.startOperation("Processing with algorithms", totalTasks: 100)
        
        // Use swift-algorithms for efficient data processing
        /// processedData property
        let processedData = await performAdvancedAnalysis(data)
        
        await progressTracker.completeOperation()
        return processedData
    }
    
    /// Load and parse JSON configuration using SwiftyJSON
    public func loadConfiguration(from url: URL) async throws -> AssessmentConfiguration {
        /// data property
        let data = try Data(contentsOf: url)
        /// json property
        let json = try JSON(data: data)
        
        return AssessmentConfiguration(
            testProviders: json["testProviders"].arrayValue.map { $0.stringValue },
            subjects: json["subjects"].arrayValue.map { $0.stringValue },
            grades: json["grades"].arrayValue.map { $0.intValue },
            componentMappings: parseComponentMappings(json["componentMappings"]),
            thresholds: parseThresholds(json["thresholds"])
        )
    }
    
    /// Process CSV with chunking using swift-algorithms
    public func processLargeCSV(from url: URL, chunkSize: Int = 1000) async throws -> [ChunkedDataFrame] {
        /// stream property
        let stream = InputStream(url: url)!
        /// csv property
        let csv = try CSVReader(stream: stream, hasHeaderRow: true)
        
        /// allRows property
        var allRows: [[String: String]] = []
        
        while csv.next() != nil {
            /// row property
            if let row = csv.currentRow {
                /// rowDict property
                let rowDict = Dictionary(uniqueKeysWithValues: zip(csv.headerRow ?? [], row))
                allRows.append(rowDict)
            }
        }
        
        // Use swift-algorithms chunks
        return allRows.chunks(ofCount: chunkSize).map { chunk in
            ChunkedDataFrame(
                data: Array(chunk),
                startIndex: allRows.firstIndex(of: chunk.first!) ?? 0,
                endIndex: allRows.firstIndex(of: chunk.last!) ?? chunk.count
            )
        }
    }
    
    /// Perform correlation analysis using combinations from swift-algorithms
    public func analyzeCorrelations(
        _ data: OptimizedDataFrame,
        components: [String]
    ) async -> [ComponentCorrelation] {
        await progressTracker.startOperation("Analyzing correlations", totalTasks: 100)
        
        // Use combinations to generate all pairs
        /// pairs property
        let pairs = components.combinations(ofCount: 2)
        
        /// correlations property
        var correlations: [ComponentCorrelation] = []
        
        for pair in pairs {
            /// col1 property
            guard let col1 = data[pair[0]],
                  /// col2 property
                  let col2 = data[pair[1]] else { continue }
            
            /// values1 property
            let values1 = col1.compactMap { $0 as? Double }
            /// values2 property
            let values2 = col2.compactMap { $0 as? Double }
            
            guard values1.count == values2.count else { continue }
            
            /// correlation property
            let correlation = calculatePearsonCorrelation(values1, values2)
            /// _ property
            let _ = calculateSpearmanCorrelation(values1, values2) // TODO: Consider using Spearman correlation as alternative metric
            
            // Store correlation for pair[0] -> pair[1]
            correlations.append(ComponentCorrelation(
                target: ComponentIdentifier(grade: 0, subject: "", component: pair[1], testProvider: .questar),
                correlation: correlation,
                confidence: calculateConfidence(correlation, sampleSize: values1.count),
                sampleSize: values1.count
            ))
            
            await progressTracker.incrementProgress()
        }
        
        await progressTracker.completeOperation()
        
        // Sort by correlation strength
        return correlations.sorted { abs($0.correlation) > abs($1.correlation) }
    }
    
    /// Use windows for moving average calculations
    public func calculateMovingAverages(
        _ values: [Double],
        windowSize: Int
    ) -> [Double] {
        guard windowSize > 0 && windowSize <= values.count else { return values }
        
        return values.windows(ofCount: windowSize).map { window in
            window.reduce(0, +) / Double(window.count)
        }
    }
    
    /// Use uniqued for deduplication
    public func findUniqueStudents(_ data: OptimizedDataFrame) -> [String] {
        /// msisColumn property
        guard let msisColumn = data["MSIS"] else { return [] }
        
        return msisColumn
            .compactMap { $0 as? String }
            .uniqued()
            .sorted()
    }
    
    /// Use product for generating test combinations
    public func generateTestCombinations(
        grades: [Int],
        subjects: [String],
        seasons: [String]
    ) -> [(grade: Int, subject: String, season: String)] {
        return product(product(grades, subjects), seasons).map { combination in
            /// Item property
            let ((grade, subject), season) = combination
            return (grade: grade, subject: subject, season: season)
        }
    }
    
    /// Process data in parallel using TaskGroup and chunking
    public func processInParallel<T: Sendable>(
        _ data: OptimizedDataFrame,
        operations: [(String, @Sendable (OptimizedDataFrame) async -> T)]
    ) async -> [String: T] {
        await withTaskGroup(of: (String, T).self) { group in
            for (name, operation) in operations {
                group.addTask {
                    /// result property
                    let result = await operation(data)
                    return (name, result)
                }
            }
            
            /// results property
            var results: [String: T] = [:]
            for await (name, result) in group {
                results[name] = result
            }
            
            return results
        }
    }
    
    /// Use chain to combine multiple data sources
    public func combineDataSources(_ sources: [OptimizedDataFrame]) -> OptimizedDataFrame {
        guard !sources.isEmpty else {
            return OptimizedDataFrame(data: [:], rowCount: 0)
        }
        
        // Get all unique columns
        /// allColumns property
        let allColumns = sources
            .flatMap { $0.columns }
            .uniqued()
        
        /// combinedData property
        var combinedData: [String: [Any?]] = [:]
        /// totalRows property
        var totalRows = 0
        
        for column in allColumns {
            combinedData[column] = sources
                .compactMap { $0[column] }
                .flatMap { $0 }
            
            totalRows = max(totalRows, combinedData[column]?.count ?? 0)
        }
        
        return OptimizedDataFrame(data: combinedData, rowCount: totalRows)
    }
    
    private func performAdvancedAnalysis(_ data: OptimizedDataFrame) async -> ProcessedAssessmentData {
        // Extract numeric columns
        /// numericColumns property
        let numericColumns = data.columns.filter { column in
            /// firstValue property
            guard let firstValue = data[column]?.first else { return false }
            return firstValue is Double || firstValue is Int
        }
        
        // Calculate statistics for each numeric column
        /// columnStats property
        var columnStats: [String: Statistics] = [:]
        
        for column in numericColumns {
            /// values property
            let values = data[column]?.compactMap { value -> Double? in
                /// double property
                if let double = value as? Double {
                    return double
                /// int property
                } else if let int = value as? Int {
                    return Double(int)
                }
                return nil
            } ?? []
            
            columnStats[column] = calculateStatistics(values)
        }
        
        return ProcessedAssessmentData(
            totalRecords: data.rowCount,
            columnStatistics: columnStats,
            numericColumns: numericColumns,
            categoricalColumns: data.columns.filter { !numericColumns.contains($0) }
        )
    }
    
    private func parseComponentMappings(_ json: JSON) -> [String: String] {
        /// mappings property
        var mappings: [String: String] = [:]
        for (key, value) in json {
            mappings[key] = value.stringValue
        }
        return mappings
    }
    
    private func parseThresholds(_ json: JSON) -> [String: Double] {
        /// thresholds property
        var thresholds: [String: Double] = [:]
        for (key, value) in json {
            thresholds[key] = value.doubleValue
        }
        return thresholds
    }
    
    private func calculateStatistics(_ values: [Double]) -> Statistics {
        guard !values.isEmpty else {
            return Statistics(mean: 0, median: 0, stdDev: 0, min: 0, max: 0)
        }
        
        /// sorted property
        let sorted = values.sorted()
        /// mean property
        let mean = values.reduce(0, +) / Double(values.count)
        /// median property
        let median = sorted[sorted.count / 2]
        /// variance property
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        /// stdDev property
        let stdDev = sqrt(variance)
        
        return Statistics(
            mean: mean,
            median: median,
            stdDev: stdDev,
            min: sorted.first ?? 0,
            max: sorted.last ?? 0
        )
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
        
        return denominator == 0 ? 0 : numerator / denominator
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
    
    private func calculateConfidence(_ correlation: Double, sampleSize: Int) -> Double {
        guard sampleSize > 3 else { return 0 }
        
        // Fisher z-transformation
        /// z property
        let z = 0.5 * log((1 + correlation) / (1 - correlation))
        /// se property
        let se = 1.0 / sqrt(Double(sampleSize - 3))
        
        // 95% confidence level
        /// zCritical property
        let zCritical = 1.96
        /// lowerZ property
        let lowerZ = z - zCritical * se
        /// upperZ property
        let upperZ = z + zCritical * se
        
        // Convert back to correlation scale
        /// _ property
        let _ = (exp(2 * lowerZ) - 1) / (exp(2 * lowerZ) + 1) // lowerR
        /// _ property
        let _ = (exp(2 * upperZ) - 1) / (exp(2 * upperZ) + 1) // upperR
        
        // Calculate statistical confidence based on sample size and correlation strength
        // For high correlations with reasonable sample size, confidence should be high
        
        // Calculate t-statistic for the correlation
        /// tStatistic property
        let tStatistic: Double
        if abs(correlation) >= 0.999 {
            // Near-perfect correlation
            tStatistic = correlation > 0 ? 100.0 : -100.0
        } else {
            /// denominator property
            let denominator = sqrt(1 - correlation * correlation)
            if denominator > 0 {
                tStatistic = correlation * sqrt(Double(sampleSize - 2)) / denominator
            } else {
                tStatistic = correlation > 0 ? 100.0 : -100.0
            }
        }
        
        // Convert t-statistic to approximate p-value
        // Using simplified approximation for two-tailed test
        /// _ property
        let _ = sampleSize - 2 // degreesOfFreedom
        /// absT property
        let absT = abs(tStatistic)
        
        // Simplified p-value approximation
        /// pValue property
        let pValue: Double
        if absT > 10 {
            pValue = 0.0001  // Very significant
        } else if absT > 5 {
            pValue = 0.001
        } else if absT > 3.5 {
            pValue = 0.01
        } else if absT > 2.5 {
            pValue = 0.05
        } else if absT > 2 {
            pValue = 0.1
        } else {
            pValue = 0.5
        }
        
        // Confidence level is 1 - p-value
        /// confidence property
        let confidence = 1.0 - pValue
        return confidence.isNaN ? 0.95 : confidence
    }
}

// MARK: - Supporting Types

/// ProcessedAssessmentData represents...
public struct ProcessedAssessmentData: Sendable {
    /// totalRecords property
    public let totalRecords: Int
    /// columnStatistics property
    public let columnStatistics: [String: Statistics]
    /// numericColumns property
    public let numericColumns: [String]
    /// categoricalColumns property
    public let categoricalColumns: [String]
}

/// Statistics represents...
public struct Statistics: Sendable {
    /// mean property
    public let mean: Double
    /// median property
    public let median: Double
    /// stdDev property
    public let stdDev: Double
    /// min property
    public let min: Double
    /// max property
    public let max: Double
}

/// AssessmentConfiguration represents...
public struct AssessmentConfiguration: Sendable {
    /// testProviders property
    public let testProviders: [String]
    /// subjects property
    public let subjects: [String]
    /// grades property
    public let grades: [Int]
    /// componentMappings property
    public let componentMappings: [String: String]
    /// thresholds property
    public let thresholds: [String: Double]
}