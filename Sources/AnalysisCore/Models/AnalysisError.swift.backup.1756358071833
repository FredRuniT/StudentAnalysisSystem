import Foundation

public enum AnalysisError: Error, LocalizedError {
    case fileNotFound(path: String)
    case invalidFileFormat(path: String)
    case parsingError(message: String)
    case dataProcessingError(message: String)
    case insufficientData(message: String)
    case correlationError(message: String)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidFileFormat(let path):
            return "Invalid file format: \(path). Supported formats: CSV, XLSX, XLS"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        case .dataProcessingError(let message):
            return "Data processing error: \(message)"
        case .insufficientData(let message):
            return "Insufficient data: \(message)"
        case .correlationError(let message):
            return "Correlation analysis error: \(message)"
        }
    }
}