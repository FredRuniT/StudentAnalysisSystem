import AnalysisCore
import Foundation
import MLX
import StatisticalEngine
import SwiftUI

@MainActor
/// CorrelationDataLoader represents...
class CorrelationDataLoader: ObservableObject {
    /// isLoading property
    @Published var isLoading = true
    /// loadingProgress property
    @Published var loadingProgress: Double = 0.0
    /// loadingMessage property
    @Published var loadingMessage = "Initializing..."
    /// topCorrelations property
    @Published var topCorrelations: [CorrelationPair] = []
    /// crossGradeCorrelations property
    @Published var crossGradeCorrelations: [CrossGradeCorrelation] = []
    /// correlationChunks property
    @Published var correlationChunks: [CorrelationChunk] = []
    /// currentChunkIndex property
    @Published var currentChunkIndex = 0
    /// totalCorrelationsLoaded property
    @Published var totalCorrelationsLoaded = 0
    
    private let mlxAccelerator = MLXAccelerator()
    private let chunkSize = 100_000_000 // 100MB chunks for 128GB system
    private var correlationCache: [String: [CorrelationPair]] = [:]
    private var totalCorrelations = 0
    
    /// CorrelationPair represents...
    struct CorrelationPair: Identifiable, Sendable {
        /// id property
        let id = UUID()
        /// source property
        let source: ComponentIdentifier
        /// target property
        let target: ComponentIdentifier
        /// correlation property
        let correlation: Double
        /// confidence property
        let confidence: Double
        /// sampleSize property
        let sampleSize: Int
        
        /// sourceName property
        var sourceName: String {
            "G\(source.grade)_\(source.subject)_\(source.component)"
        }
        
        /// targetName property
        var targetName: String {
            "G\(target.grade)_\(target.subject)_\(target.component)"
        }
    }
    
    /// CrossGradeCorrelation represents...
    struct CrossGradeCorrelation: Identifiable, Sendable {
        /// id property
        let id = UUID()
        /// earlyGrade property
        let earlyGrade: Int
        /// laterGrade property
        let laterGrade: Int
        /// subject property
        let subject: String
        /// averageCorrelation property
        let averageCorrelation: Double
        /// count property
        let count: Int
        /// strongestPair property
        let strongestPair: CorrelationPair?
    }
    
    /// CorrelationChunk represents...
    struct CorrelationChunk: Identifiable, Sendable {
        /// id property
        let id = UUID()
        /// startIndex property
        let startIndex: Int
        /// endIndex property
        let endIndex: Int
        /// correlations property
        let correlations: [CorrelationPair]
        /// isLoaded property
        let isLoaded: Bool
    }
    
    /// loadCorrelationsOptimized function description
    func loadCorrelationsOptimized() async {
        loadingMessage = "Loading correlation data..."
        isLoading = true
        
        // Direct JSON parsing approach
        await loadFromJSON()
    }
    
    private func loadFromJSON() async {
        print("📂 Starting loadFromJSON...")
        // Try multiple possible locations for the correlation data
        /// possiblePaths property
        let possiblePaths = [
            // Demo file for immediate testing (smaller, realistic data)
            URL(fileURLWithPath: "/Users/fredrickburns/Code_Repositories/StudentAnalysisSystem/Output/demo_correlation_model.json"),
            // Relative to current working directory (for command line runs)
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Output/demo_correlation_model.json"),
            // Full correlation model (backup)
            URL(fileURLWithPath: "/Users/fredrickburns/Code_Repositories/StudentAnalysisSystem/Output/correlation_model.json"),
            // Relative to bundle (for app bundle runs)
            Bundle.main.url(forResource: "demo_correlation_model", withExtension: "json", subdirectory: "Output")
        ].compactMap { $0 }
        
        print("📂 Checking paths: \(possiblePaths.map { $0.path })")
        
        /// jsonURL property
        var jsonURL: URL?
        /// foundPath property
        var foundPath: String = "No valid paths found"
        
        for path in possiblePaths {
            print("📂 Checking if exists: \(path.path)")
            if FileManager.default.fileExists(atPath: path.path) {
                jsonURL = path
                foundPath = path.path
                print("✅ Found file at: \(foundPath)")
                break
            }
        }
        
        /// validURL property
        guard let validURL = jsonURL else {
            print("❌ No correlation file found!")
            await MainActor.run {
                loadingMessage = "Correlation file not found. Searched: \(possiblePaths.map { $0.path }.joined(separator: ", ")). Current dir: \(FileManager.default.currentDirectoryPath)"
                isLoading = false
                print("❌ File not found error set, isLoading = false")
            }
            return
        }
        
        do {
            print("📖 Reading data from: \(foundPath)...")
            loadingMessage = "Reading correlation data from: \(foundPath)..."
            
            // Load the entire JSON file into memory (we have 128GB)
            /// data property
            let data = try Data(contentsOf: validURL)
            
            loadingMessage = "Parsing correlations..."
            loadingProgress = 0.2
            
            // Parse JSON structure
            print("📖 Parsing JSON data of size: \(data.count) bytes")
            /// json property
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            print("📖 JSON parsed, looking for 'correlations' key...")
            /// correlationsArray property
            guard let correlationsArray = json?["correlations"] as? [[String: Any]] else {
                print("❌ Invalid JSON structure - no 'correlations' array found")
                print("❌ JSON keys found: \(json?.keys.joined(separator: ", ") ?? "none")")
                loadingMessage = "Invalid JSON structure"
                isLoading = false
                return
            }
            
            print("✅ Found correlations array with \(correlationsArray.count) items")
            await processCorrelations(correlationsArray)
            
        } catch {
            print("❌ Error loading/parsing JSON: \(error)")
            await MainActor.run {
                loadingMessage = "Error loading correlations: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func processCorrelations(_ correlationsArray: [[String: Any]]) async {
        /// allPairs property
        var allPairs: [CorrelationPair] = []
        /// crossGradeMap property
        var crossGradeMap: [String: CrossGradeCorrelation] = [:]
        /// totalItems property
        let totalItems = correlationsArray.count
        /// processedCount property
        var processedCount = 0
        
        loadingMessage = "Processing \(totalItems) correlation sets..."
        print("📊 Processing \(totalItems) correlation sets from JSON...")
        
        // Process in batches to update UI
        for (index, correlationEntry) in correlationsArray.enumerated() {
            autoreleasepool {
                /// sourceDict property
                guard let sourceDict = correlationEntry["sourceComponent"] as? [String: Any],
                      /// correlationsList property
                      let correlationsList = correlationEntry["correlations"] as? [[String: Any]] else { return }
                
                /// providerString property
                let providerString = sourceDict["testProvider"] as? String ?? "NWEA"
                /// provider property
                let provider = TestProvider(rawValue: providerString) ?? .nwea
                
                /// source property
                let source = ComponentIdentifier(
                    grade: sourceDict["grade"] as? Int ?? 0,
                    subject: sourceDict["subject"] as? String ?? "",
                    component: sourceDict["component"] as? String ?? "",
                    testProvider: provider
                )
                
                // Process each correlation for this source
                for correlationDict in correlationsList {
                    /// targetDict property
                    guard let targetDict = correlationDict["target"] as? [String: Any],
                          /// correlationValue property
                          let correlationValue = correlationDict["correlation"] as? Double,
                          /// confidence property
                          let confidence = correlationDict["confidence"] as? Double,
                          /// sampleSize property
                          let sampleSize = correlationDict["sampleSize"] as? Int,
                          correlationValue > 0.5 else { continue }
                    
                    /// targetProviderString property
                    let targetProviderString = targetDict["testProvider"] as? String ?? "NWEA"
                    /// targetProvider property
                    let targetProvider = TestProvider(rawValue: targetProviderString) ?? .nwea
                    
                    /// target property
                    let target = ComponentIdentifier(
                        grade: targetDict["grade"] as? Int ?? 0,
                        subject: targetDict["subject"] as? String ?? "",
                        component: targetDict["component"] as? String ?? "",
                        testProvider: targetProvider
                    )
                    
                    /// pair property
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
                        /// key property
                        let key = "\(source.grade)-\(target.grade)-\(source.subject)"
                        
                        /// existing property
                        if let existing = crossGradeMap[key] {
                            /// newCount property
                            let newCount = existing.count + 1
                            /// newAvg property
                            let newAvg = (existing.averageCorrelation * Double(existing.count) + correlationValue) / Double(newCount)
                            
                            /// strongestPair property
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
                    /// progress property
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
            /// sortedPairs property
            let sortedPairs = allPairs.sorted { $0.correlation > $1.correlation }
            
            // Take top correlations for display
            self.topCorrelations = Array(sortedPairs.prefix(1000))
            print("✅ Set topCorrelations with \(self.topCorrelations.count) pairs")
            
            // Sort cross-grade correlations
            self.crossGradeCorrelations = Array(crossGradeMap.values)
                .sorted { $0.averageCorrelation > $1.averageCorrelation }
            
            self.totalCorrelations = allPairs.count
            self.totalCorrelationsLoaded = allPairs.count
            self.loadingMessage = "Loaded \(allPairs.count) significant correlations"
            print("✅ Loaded \(allPairs.count) total correlations")
            self.isLoading = false
            self.loadingProgress = 1.0
            
            // Create chunks for pagination if needed
            if sortedPairs.count > 1000 {
                self.createCorrelationChunks(from: sortedPairs)
            }
        }
    }
    
    private func createCorrelationChunks(from pairs: [CorrelationPair]) {
        /// chunks property
        var chunks: [CorrelationChunk] = []
        /// chunkSize property
        let chunkSize = 500 // Display 500 correlations per chunk
        
        for i in stride(from: 0, to: pairs.count, by: chunkSize) {
            /// endIndex property
            let endIndex = min(i + chunkSize, pairs.count)
            /// chunkPairs property
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
    
    /// loadChunk function description
    func loadChunk(at index: Int) {
        guard index < correlationChunks.count else { return }
        currentChunkIndex = index
    }
    
    /// filterCorrelations function description
    func filterCorrelations(
        subject: String? = nil,
        grade: Int? = nil,
        minCorrelation: Double = 0.7
    ) -> [CorrelationPair] {
        /// cacheKey property
        let cacheKey = "\(subject ?? "all")_\(grade ?? 0)_\(minCorrelation)"
        
        /// cached property
        if let cached = correlationCache[cacheKey] {
            return cached
        }
        
        /// filtered property
        var filtered = topCorrelations
        
        /// subject property
        if let subject = subject, subject != "All" {
            filtered = filtered.filter { 
                $0.source.subject == subject || $0.target.subject == subject 
            }
        }
        
        /// grade property
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
    
    /// getCrossGradeInsights function description
    func getCrossGradeInsights(fromGrade: Int, toGrade: Int) -> [CrossGradeCorrelation] {
        return crossGradeCorrelations.filter {
            $0.earlyGrade == fromGrade && $0.laterGrade == toGrade
        }
    }
    
    /// getStrongestPredictors function description
    func getStrongestPredictors(for grade: Int, subject: String? = nil) -> [CorrelationPair] {
        /// predictors property
        var predictors = topCorrelations.filter { $0.target.grade == grade }
        
        /// subject property
        if let subject = subject {
            predictors = predictors.filter { $0.target.subject == subject }
        }
        
        return Array(predictors.prefix(20))
    }
    
    // MARK: - Network Visualization Data
    
    /// loadCorrelationData function description
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
        /// correlationMaps property
        var correlationMaps: [String: [ComponentCorrelation]] = [:]
        
        for pair in topCorrelations.prefix(5000) { // Limit for performance
            /// sourceKey property
            let sourceKey = "\(pair.source.grade)_\(pair.source.subject)_\(pair.source.component)"
            
            /// componentCorrelation property
            let componentCorrelation = ComponentCorrelation(
                target: pair.target,
                correlation: pair.correlation,
                confidence: pair.confidence,
                sampleSize: pair.sampleSize
            )
            
            /// existing property
            if var existing = correlationMaps[sourceKey] {
                existing.append(componentCorrelation)
                correlationMaps[sourceKey] = existing
            } else {
                correlationMaps[sourceKey] = [componentCorrelation]
            }
        }
        
        // Convert to ComponentCorrelationMap array
        /// result property
        var result: [ComponentCorrelationMap] = []
        for (sourceKey, correlations) in correlationMaps {
            // Parse the source key back to find the source component
            /// firstCorrelation property
            if let firstCorrelation = correlations.first,
               /// sourcePair property
               let sourcePair = topCorrelations.first(where: { 
                   "\($0.source.grade)_\($0.source.subject)_\($0.source.component)" == sourceKey 
               }) {
                /// correlationMap property
                let correlationMap = ComponentCorrelationMap(
                    sourceComponent: sourcePair.source,
                    correlations: correlations
                )
                result.append(correlationMap)
            }
        }
        
        print("📦 Returning \(result.count) ComponentCorrelationMaps to CorrelationNetworkView")
        return result
    }
}