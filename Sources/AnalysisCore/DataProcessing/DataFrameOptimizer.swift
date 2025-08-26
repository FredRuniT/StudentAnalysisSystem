import Foundation
import Algorithms

public struct OptimizedDataFrame: @unchecked Sendable {
    private let data: [String: [Any?]]
    public let rowCount: Int
    public let columns: [String]
    
    public init(data: [String: [Any?]], rowCount: Int) {
        self.data = data
        self.rowCount = rowCount
        self.columns = Array(data.keys).sorted()
    }
    
    public subscript(column: String) -> [Any?]? {
        data[column]
    }
    
    public subscript(column: String, row: Int) -> Any? {
        guard row < rowCount,
              let columnData = data[column],
              row < columnData.count else { return nil }
        return columnData[row]
    }
    
    public func chunked(size: Int) -> [ChunkedDataFrame] {
        var chunks: [ChunkedDataFrame] = []
        
        for startRow in stride(from: 0, to: rowCount, by: size) {
            let endRow = min(startRow + size, rowCount)
            var chunkData: [[String: Any?]] = []
            
            for row in startRow..<endRow {
                var rowData: [String: Any?] = [:]
                for column in columns {
                    if let value = self[column, row] {
                        rowData[column] = value
                    }
                }
                chunkData.append(rowData)
            }
            
            chunks.append(ChunkedDataFrame(
                data: chunkData,
                startIndex: startRow,
                endIndex: endRow
            ))
        }
        
        return chunks
    }
    
    public func filter(column: String, predicate: (Any?) -> Bool) -> OptimizedDataFrame {
        var filteredData: [String: [Any?]] = [:]
        columns.forEach { filteredData[$0] = [] }
        
        var newRowCount = 0
        
        for row in 0..<rowCount {
            if let value = self[column, row], predicate(value) {
                for col in columns {
                    filteredData[col]?.append(self[col, row])
                }
                newRowCount += 1
            }
        }
        
        return OptimizedDataFrame(data: filteredData, rowCount: newRowCount)
    }
    
    public func select(columns: [String]) -> OptimizedDataFrame {
        let selectedData = columns.reduce(into: [String: [Any?]]()) { result, column in
            if let columnData = data[column] {
                result[column] = columnData
            }
        }
        
        return OptimizedDataFrame(data: selectedData, rowCount: rowCount)
    }
}

public struct ChunkedDataFrame: @unchecked Sendable {
    public let data: [[String: Any?]]
    public let startIndex: Int
    public let endIndex: Int
    
    public var count: Int { data.count }
}

public extension OptimizedDataFrame {
    func memoryFootprint() -> String {
        let bytesPerRow = columns.count * 16 // Rough estimate
        let totalBytes = bytesPerRow * rowCount
        let mb = Double(totalBytes) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }
}