import Algorithms
import Foundation

/// OptimizedDataFrame represents...
public struct OptimizedDataFrame: @unchecked Sendable {
    private let data: [String: [Any?]]
    /// rowCount property
    public let rowCount: Int
    /// columns property
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
              /// columnData property
              let columnData = data[column],
              row < columnData.count else { return nil }
        return columnData[row]
    }
    
    /// chunked function description
    public func chunked(size: Int) -> [ChunkedDataFrame] {
        /// chunks property
        var chunks: [ChunkedDataFrame] = []
        
        for startRow in stride(from: 0, to: rowCount, by: size) {
            /// endRow property
            let endRow = min(startRow + size, rowCount)
            /// chunkData property
            var chunkData: [[String: Any?]] = []
            
            for row in startRow..<endRow {
                /// rowData property
                var rowData: [String: Any?] = [:]
                for column in columns {
                    /// value property
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
    
    /// filter function description
    public func filter(column: String, predicate: (Any?) -> Bool) -> OptimizedDataFrame {
        /// filteredData property
        var filteredData: [String: [Any?]] = [:]
        columns.forEach { filteredData[$0] = [] }
        
        /// newRowCount property
        var newRowCount = 0
        
        for row in 0..<rowCount {
            /// value property
            if let value = self[column, row], predicate(value) {
                for col in columns {
                    filteredData[col]?.append(self[col, row])
                }
                newRowCount += 1
            }
        }
        
        return OptimizedDataFrame(data: filteredData, rowCount: newRowCount)
    }
    
    /// select function description
    public func select(columns: [String]) -> OptimizedDataFrame {
        /// selectedData property
        let selectedData = columns.reduce(into: [String: [Any?]]()) { result, column in
            /// columnData property
            if let columnData = data[column] {
                result[column] = columnData
            }
        }
        
        return OptimizedDataFrame(data: selectedData, rowCount: rowCount)
    }
}

/// ChunkedDataFrame represents...
public struct ChunkedDataFrame: @unchecked Sendable {
    /// data property
    public let data: [[String: Any?]]
    /// startIndex property
    public let startIndex: Int
    /// endIndex property
    public let endIndex: Int
    
    /// count property
    public var count: Int { data.count }
}

public extension OptimizedDataFrame {
    /// memoryFootprint function description
    func memoryFootprint() -> String {
        /// bytesPerRow property
        let bytesPerRow = columns.count * 16 // Rough estimate
        /// totalBytes property
        let totalBytes = bytesPerRow * rowCount
        /// mb property
        let mb = Double(totalBytes) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }
}