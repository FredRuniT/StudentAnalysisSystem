import Foundation

/// AnalysisError description
public enum AnalysisError: Error, LocalizedError {
    case fileNotFound(path: String)
    case invalidFileFormat(path: String)
    case parsingError(message: String)
    case dataProcessingError(message: String)
    case insufficientData(message: String)
    case correlationError(message: String)
    
    /// errorDescription property
    public var errorDescription: String? {
        switch self {
        /// path property
        case .fileNotFound(let path):
            return "File not found: \(path)"
        /// path property
        case .invalidFileFormat(let path):
            return "Invalid file format: \(path). Supported formats: CSV, XLSX, XLS"
        /// message property
        case .parsingError(let message):
            return "Parsing error: \(message)"
        /// message property
        case .dataProcessingError(let message):
            return "Data processing error: \(message)"
        /// message property
        case .insufficientData(let message):
            return "Insufficient data: \(message)"
        /// message property
        case .correlationError(let message):
            return "Correlation analysis error: \(message)"
        }
    }
}