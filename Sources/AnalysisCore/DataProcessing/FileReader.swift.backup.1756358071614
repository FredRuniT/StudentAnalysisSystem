import Foundation
import CoreXLSX
import CSV
import MLX
import Algorithms

public actor FileReader {
    private let chunkSize = 5000
    private let progressTracker: ProgressTracker
    
    public init() {
        self.progressTracker = ProgressTracker()
    }
    
    public func readAssessmentFile(from url: URL) async throws -> OptimizedDataFrame {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AnalysisError.fileNotFound(path: url.path)
        }
        
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "csv":
            return try await readCSVOptimized(from: url)
        case "xlsx", "xls":
            return try await readExcelOptimized(from: url)
        default:
            throw AnalysisError.invalidFileFormat(path: url.path)
        }
    }
    
    private func readCSVOptimized(from url: URL) async throws -> OptimizedDataFrame {
        await progressTracker.startOperation("Reading CSV: \(url.lastPathComponent)", totalTasks: 100)
        
        let stream = InputStream(url: url)!
        let csv = try CSVReader(stream: stream, hasHeaderRow: true)
        
        let headers = csv.headerRow ?? []
        var columns: [String: [Any?]] = Dictionary(uniqueKeysWithValues: headers.map { ($0, [Any?]()) })
        
        // Process in parallel chunks using TaskGroup
        let rows = try await withThrowingTaskGroup(of: [[String: String]].self) { group in
            var chunks: [[String]] = []
            var currentChunk: [String] = []
            
            while csv.next() != nil {
                if let row = csv.currentRow {
                    currentChunk.append(row.joined(separator: ","))
                    
                    if currentChunk.count >= chunkSize {
                        let chunkToProcess = currentChunk
                        chunks.append(chunkToProcess)
                        currentChunk = []
                        
                        group.addTask {
                            return await self.parseCSVChunk(chunkToProcess, headers: headers)
                        }
                    }
                }
            }
            
            // Process remaining chunk
            if !currentChunk.isEmpty {
                group.addTask {
                    return await self.parseCSVChunk(currentChunk, headers: headers)
                }
            }
            
            var allRows: [[String: String]] = []
            for try await chunkResult in group {
                allRows.append(contentsOf: chunkResult)
                await progressTracker.incrementProgress(by: 100 / chunks.count)
            }
            
            return allRows
        }
        
        // Consolidate results
        for row in rows {
            for header in headers {
                columns[header]?.append(row[header])
            }
        }
        
        await progressTracker.completeOperation()
        return OptimizedDataFrame(data: columns, rowCount: rows.count)
    }
    
    private func parseCSVChunk(_ lines: [String], headers: [String]) async -> [[String: String]] {
        lines.map { line in
            let values = line.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
            
            return Dictionary(uniqueKeysWithValues: zip(headers, values))
        }
    }
    
    private func readExcelOptimized(from url: URL) async throws -> OptimizedDataFrame {
        await progressTracker.startOperation("Reading Excel: \(url.lastPathComponent)", totalTasks: 100)
        
        guard let file = XLSXFile(filepath: url.path) else {
            throw AnalysisError.fileNotFound(path: url.path)
        }
        
        // Get the first worksheet
        guard let worksheetPaths = try? file.parseWorksheetPaths(),
              let firstPath = worksheetPaths.first else {
            throw AnalysisError.parsingError(message: "No worksheets found in Excel file")
        }
        
        let worksheet = try file.parseWorksheet(at: firstPath)
        
        // Parse the worksheet data
        var columns: [String: [Any?]] = [:]
        var headers: [String] = []
        var rowCount = 0
        
        if let sharedStrings = try? file.parseSharedStrings() {
            // Get headers from first row
            if let firstRow = worksheet.data?.rows.first {
                headers = firstRow.cells.map { cell in
                    cell.stringValue(sharedStrings) ?? "Column_\(cell.reference.column)"
                }
                columns = Dictionary(uniqueKeysWithValues: headers.map { ($0, [Any?]()) })
            }
            
            // Parse data rows
            for (index, row) in (worksheet.data?.rows ?? []).enumerated() {
                if index == 0 { continue } // Skip header row
                
                for (colIndex, cell) in row.cells.enumerated() {
                    if colIndex < headers.count {
                        let value = cell.value ?? cell.stringValue(sharedStrings)
                        columns[headers[colIndex]]?.append(value)
                    }
                }
                rowCount += 1
                
                if rowCount % 1000 == 0 {
                    await progressTracker.incrementProgress(by: 10)
                }
            }
        }
        
        await progressTracker.completeOperation()
        return OptimizedDataFrame(data: columns, rowCount: rowCount)
    }
}
