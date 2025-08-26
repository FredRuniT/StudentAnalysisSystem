import Foundation
import Algorithms
import SwiftyJSON
import CSV

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
        let processedData = await performAdvancedAnalysis(data)
        
        await progressTracker.completeOperation()
        return processedData
    }
    
    /// Load and parse JSON configuration using SwiftyJSON
    public func loadConfiguration(from url: URL) async throws -> AssessmentConfiguration {
        let data = try Data(contentsOf: url)
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
        let stream = InputStream(url: url)!
        let csv = try CSVReader(stream: stream, hasHeaderRow: true)
        
        var allRows: [[String: String]] = []
        
        while csv.next() != nil {
            if let row = csv.currentRow {
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
        let pairs = components.combinations(ofCount: 2)
        
        var correlations: [ComponentCorrelation] = []
        
        for pair in pairs {
            guard let col1 = data[pair[0]],
                  let col2 = data[pair[1]] else { continue }
            
            let values1 = col1.compactMap { $0 as? Double }
            let values2 = col2.compactMap { $0 as? Double }
            
            guard values1.count == values2.count else { continue }
            
            let correlation = calculatePearsonCorrelation(values1, values2)
            let spearman = calculateSpearmanCorrelation(values1, values2)
            
            // Store correlation for pair[0] -> pair[1]
            correlations.append(ComponentCorrelation(
                target: ComponentIdentifier(grade: 0, subject: "", component: pair[1]),
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
                    let result = await operation(data)
                    return (name, result)
                }
            }
            
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
        let allColumns = sources
            .flatMap { $0.columns }
            .uniqued()
        
        var combinedData: [String: [Any?]] = [:]
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
        let numericColumns = data.columns.filter { column in
            guard let firstValue = data[column]?.first else { return false }
            return firstValue is Double || firstValue is Int
        }
        
        // Calculate statistics for each numeric column
        var columnStats: [String: Statistics] = [:]
        
        for column in numericColumns {
            let values = data[column]?.compactMap { value -> Double? in
                if let double = value as? Double {
                    return double
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
        var mappings: [String: String] = [:]
        for (key, value) in json {
            mappings[key] = value.stringValue
        }
        return mappings
    }
    
    private func parseThresholds(_ json: JSON) -> [String: Double] {
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
        
        let sorted = values.sorted()
        let mean = values.reduce(0, +) / Double(values.count)
        let median = sorted[sorted.count / 2]
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
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
    
    private func calculateConfidence(_ correlation: Double, sampleSize: Int) -> Double {
        guard sampleSize > 3 else { return 0 }
        
        // Fisher z-transformation
        let z = 0.5 * log((1 + correlation) / (1 - correlation))
        let se = 1.0 / sqrt(Double(sampleSize - 3))
        
        // 95% confidence level
        let zCritical = 1.96
        let lowerZ = z - zCritical * se
        let upperZ = z + zCritical * se
        
        // Convert back to correlation scale
        let lowerR = (exp(2 * lowerZ) - 1) / (exp(2 * lowerZ) + 1)
        let upperR = (exp(2 * upperZ) - 1) / (exp(2 * upperZ) + 1)
        
        // Confidence is based on interval width
        let intervalWidth = upperR - lowerR
        return max(0, min(1, 1 - intervalWidth))
    }
}

// MARK: - Supporting Types

public struct ProcessedAssessmentData: Sendable {
    public let totalRecords: Int
    public let columnStatistics: [String: Statistics]
    public let numericColumns: [String]
    public let categoricalColumns: [String]
}

public struct Statistics: Sendable {
    public let mean: Double
    public let median: Double
    public let stdDev: Double
    public let min: Double
    public let max: Double
}

public struct AssessmentConfiguration: Sendable {
    public let testProviders: [String]
    public let subjects: [String]
    public let grades: [Int]
    public let componentMappings: [String: String]
    public let thresholds: [String: Double]
}