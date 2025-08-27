import AnalysisCore
import Foundation
import MLX
import StatisticalEngine
import SwiftUI

@MainActor
class CorrelationDataLoader: ObservableObject {
    @Published var isLoading = true
    @Published var loadingProgress: Double = 0.0
    @Published var loadingMessage = "Initializing..."
    @Published var topCorrelations: [CorrelationPair] = []
    @Published var crossGradeCorrelations: [CrossGradeCorrelation] = []
    @Published var correlationChunks: [CorrelationChunk] = []
    @Published var currentChunkIndex = 0
    @Published var totalCorrelationsLoaded = 0
    
    private let mlxAccelerator = MLXAccelerator()
    private let chunkSize = 100_000_000 // 100MB chunks for 128GB system
    private var correlationCache: [String: [CorrelationPair]] = [:]
    private var totalCorrelations = 0
    
    struct CorrelationPair: Identifiable, Sendable {
        let id = UUID()
        let source: ComponentIdentifier
        let target: ComponentIdentifier
        let correlation: Double
        let confidence: Double
        let sampleSize: Int
        
        var sourceName: String {
            "G\(source.grade)_\(source.subject)_\(source.component)"
        }
        
        var targetName: String {
            "G\(target.grade)_\(target.subject)_\(target.component)"
        }
    }
    
    struct CrossGradeCorrelation: Identifiable, Sendable {
        let id = UUID()
        let earlyGrade: Int
        let laterGrade: Int
        let subject: String
        let averageCorrelation: Double
        let count: Int
        let strongestPair: CorrelationPair?
    }
    
    struct CorrelationChunk: Identifiable, Sendable {
        let id = UUID()
        let startIndex: Int
        let endIndex: Int
        let correlations: [CorrelationPair]
        let isLoaded: Bool
    }
    
    func loadCorrelationsOptimized() async {
        loadingMessage = "Loading correlation data..."
        isLoading = true
        
        // Direct JSON parsing approach
        await loadFromJSON()
    }
    
    private func loadFromJSON() async {
        // Try multiple possible locations for the correlation data
        let possiblePaths = [
            // Demo file for immediate testing (smaller, realistic data)
            URL(fileURLWithPath: "/Users/schoolday/Code_Repositories/StudentAnalysisSystem/Output/demo_correlation_model.json"),
            // Relative to current working directory (for command line runs)
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Output/demo_correlation_model.json"),
            // Full correlation model (backup)
            URL(fileURLWithPath: "/Users/schoolday/Code_Repositories/StudentAnalysisSystem/Output/correlation_model.json"),
            // Relative to bundle (for app bundle runs)
            Bundle.main.url(forResource: "demo_correlation_model", withExtension: "json", subdirectory: "Output")
        ].compactMap { $0 }
        
        var jsonURL: URL?
        var foundPath: String = "No valid paths found"
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path.path) {
                jsonURL = path
                foundPath = path.path
                break
            }
        }
        
        guard let validURL = jsonURL else {
            await MainActor.run {
                loadingMessage = "Correlation file not found. Searched: \(possiblePaths.map { $0.path }.joined(separator: ", ")). Current dir: \(FileManager.default.currentDirectoryPath)"
                isLoading = false
            }
            return
        }
        
        do {
            loadingMessage = "Reading correlation data from: \(foundPath)..."
            
            // Load the entire JSON file into memory (we have 128GB)
            let data = try Data(contentsOf: validURL)
            
            loadingMessage = "Parsing correlations..."
            loadingProgress = 0.2
            
            // Parse JSON structure
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let correlationsArray = json?["correlations"] as? [[String: Any]] else {
                loadingMessage = "Invalid JSON structure"
                isLoading = false
                return
            }
            
            await processCorrelations(correlationsArray)
            
        } catch {
            await MainActor.run {
                loadingMessage = "Error loading correlations: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func processCorrelations(_ correlationsArray: [[String: Any]]) async {
        var allPairs: [CorrelationPair] = []
        var crossGradeMap: [String: CrossGradeCorrelation] = [:]
        let totalItems = correlationsArray.count
        var processedCount = 0
        
        loadingMessage = "Processing \(totalItems) correlation sets..."
        
        // Process in batches to update UI
        for (index, correlationEntry) in correlationsArray.enumerated() {
            autoreleasepool {
                guard let sourceDict = correlationEntry["sourceComponent"] as? [String: Any],
                      let correlationsList = correlationEntry["correlations"] as? [[String: Any]] else { return }
                
                let providerString = sourceDict["testProvider"] as? String ?? "NWEA"
                let provider = TestProvider(rawValue: providerString) ?? .nwea
                
                let source = ComponentIdentifier(
                    grade: sourceDict["grade"] as? Int ?? 0,
                    subject: sourceDict["subject"] as? String ?? "",
                    component: sourceDict["component"] as? String ?? "",
                    testProvider: provider
                )
                
                // Process each correlation for this source
                for correlationDict in correlationsList {
                    guard let targetDict = correlationDict["target"] as? [String: Any],
                          let correlationValue = correlationDict["correlation"] as? Double,
                          let confidence = correlationDict["confidence"] as? Double,
                          let sampleSize = correlationDict["sampleSize"] as? Int,
                          correlationValue > 0.5 else { continue }
                    
                    let targetProviderString = targetDict["testProvider"] as? String ?? "NWEA"
                    let targetProvider = TestProvider(rawValue: targetProviderString) ?? .nwea
                    
                    let target = ComponentIdentifier(
                        grade: targetDict["grade"] as? Int ?? 0,
                        subject: targetDict["subject"] as? String ?? "",
                        component: targetDict["component"] as? String ?? "",
                        testProvider: targetProvider
                    )
                    
                    let pair = CorrelationPair(
                        source: source,
                        target: target,
                        correlation: correlationValue,
                        confidence: confidence,
                        sampleSize: sampleSize
                    )
                    
                    allPairs.append(pair)
                    
                    // Track cross-grade patterns
                    if target.grade > source.grade && correlationValue > 0.7 {
                        let key = "\(source.grade)-\(target.grade)-\(source.subject)"
                        
                        if let existing = crossGradeMap[key] {
                            let newCount = existing.count + 1
                            let newAvg = (existing.averageCorrelation * Double(existing.count) + correlationValue) / Double(newCount)
                            
                            let strongestPair = correlationValue > (existing.strongestPair?.correlation ?? 0) ? pair : existing.strongestPair
                            
                            crossGradeMap[key] = CrossGradeCorrelation(
                                earlyGrade: source.grade,
                                laterGrade: target.grade,
                                subject: source.subject,
                                averageCorrelation: newAvg,
                                count: newCount,
                                strongestPair: strongestPair
                            )
                        } else {
                            crossGradeMap[key] = CrossGradeCorrelation(
                                earlyGrade: source.grade,
                                laterGrade: target.grade,
                                subject: source.subject,
                                averageCorrelation: correlationValue,
                                count: 1,
                                strongestPair: pair
                            )
                        }
                    }
                }
                
                processedCount += 1
                
                // Update progress periodically
                if index % 100 == 0 {
                    let progress = Double(index) / Double(totalItems)
                    Task { @MainActor in
                        self.loadingProgress = progress
                        self.loadingMessage = "Processing correlations... \(Int(progress * 100))%"
                        self.totalCorrelationsLoaded = allPairs.count
                    }
                }
            }
            
            // Limit to reasonable number for UI performance
            if allPairs.count > 50000 {
                break
            }
        }
        
        // Sort and update UI
        await MainActor.run {
            // Sort by correlation strength
            let sortedPairs = allPairs.sorted { $0.correlation > $1.correlation }
            
            // Take top correlations for display
            self.topCorrelations = Array(sortedPairs.prefix(1000))
            
            // Sort cross-grade correlations
            self.crossGradeCorrelations = Array(crossGradeMap.values)
                .sorted { $0.averageCorrelation > $1.averageCorrelation }
            
            self.totalCorrelations = allPairs.count
            self.totalCorrelationsLoaded = allPairs.count
            self.loadingMessage = "Loaded \(allPairs.count) significant correlations"
            self.isLoading = false
            self.loadingProgress = 1.0
            
            // Create chunks for pagination if needed
            if sortedPairs.count > 1000 {
                self.createCorrelationChunks(from: sortedPairs)
            }
        }
    }
    
    private func createCorrelationChunks(from pairs: [CorrelationPair]) {
        var chunks: [CorrelationChunk] = []
        let chunkSize = 500 // Display 500 correlations per chunk
        
        for i in stride(from: 0, to: pairs.count, by: chunkSize) {
            let endIndex = min(i + chunkSize, pairs.count)
            let chunkPairs = Array(pairs[i..<endIndex])
            
            chunks.append(CorrelationChunk(
                startIndex: i,
                endIndex: endIndex,
                correlations: chunkPairs,
                isLoaded: i == 0 // Only load first chunk initially
            ))
        }
        
        correlationChunks = chunks
    }
    
    func loadChunk(at index: Int) {
        guard index < correlationChunks.count else { return }
        currentChunkIndex = index
    }
    
    func filterCorrelations(
        subject: String? = nil,
        grade: Int? = nil,
        minCorrelation: Double = 0.7
    ) -> [CorrelationPair] {
        let cacheKey = "\(subject ?? "all")_\(grade ?? 0)_\(minCorrelation)"
        
        if let cached = correlationCache[cacheKey] {
            return cached
        }
        
        var filtered = topCorrelations
        
        if let subject = subject, subject != "All" {
            filtered = filtered.filter { 
                $0.source.subject == subject || $0.target.subject == subject 
            }
        }
        
        if let grade = grade {
            filtered = filtered.filter { 
                $0.source.grade == grade || $0.target.grade == grade 
            }
        }
        
        filtered = filtered.filter { $0.correlation >= minCorrelation }
        
        // Cache the result
        correlationCache[cacheKey] = filtered
        return filtered
    }
    
    func getCrossGradeInsights(fromGrade: Int, toGrade: Int) -> [CrossGradeCorrelation] {
        return crossGradeCorrelations.filter {
            $0.earlyGrade == fromGrade && $0.laterGrade == toGrade
        }
    }
    
    func getStrongestPredictors(for grade: Int, subject: String? = nil) -> [CorrelationPair] {
        var predictors = topCorrelations.filter { $0.target.grade == grade }
        
        if let subject = subject {
            predictors = predictors.filter { $0.target.subject == subject }
        }
        
        return Array(predictors.prefix(20))
    }
    
    // MARK: - Network Visualization Data
    
    func loadCorrelationData() async throws -> [ComponentCorrelationMap] {
        // Load correlations if not already loaded
        if topCorrelations.isEmpty && !isLoading {
            await loadCorrelationsOptimized()
        }
        
        // Wait for loading to complete if needed
        while isLoading {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        // Convert CorrelationPair data to ComponentCorrelationMap format
        var correlationMaps: [String: [ComponentCorrelation]] = [:]
        
        for pair in topCorrelations.prefix(5000) { // Limit for performance
            let sourceKey = "\(pair.source.grade)_\(pair.source.subject)_\(pair.source.component)"
            
            let componentCorrelation = ComponentCorrelation(
                target: pair.target,
                correlation: pair.correlation,
                confidence: pair.confidence,
                sampleSize: pair.sampleSize
            )
            
            if var existing = correlationMaps[sourceKey] {
                existing.append(componentCorrelation)
                correlationMaps[sourceKey] = existing
            } else {
                correlationMaps[sourceKey] = [componentCorrelation]
            }
        }
        
        // Convert to ComponentCorrelationMap array
        var result: [ComponentCorrelationMap] = []
        for (sourceKey, correlations) in correlationMaps {
            // Parse the source key back to find the source component
            if let firstCorrelation = correlations.first,
               let sourcePair = topCorrelations.first(where: { 
                   "\($0.source.grade)_\($0.source.subject)_\($0.source.component)" == sourceKey 
               }) {
                let correlationMap = ComponentCorrelationMap(
                    sourceComponent: sourcePair.source,
                    correlations: correlations
                )
                result.append(correlationMap)
            }
        }
        
        return result
    }
}