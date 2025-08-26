import Foundation
import AnalysisCore
import PredictiveModeling
import IndividualLearningPlan

public actor ReportBuilder {
    private let dateFormatter: DateFormatter
    
    public init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
    public func generateComprehensiveReport(
        analysisResults: AnalysisResults,
        format: ReportFormat
    ) async -> String {
        switch format {
        case .text:
            return await generateTextReport(analysisResults)
        case .markdown:
            return await generateMarkdownReport(analysisResults)
        case .html:
            return await generateHTMLReport(analysisResults)
        }
    }
    
    private func generateTextReport(_ results: AnalysisResults) async -> String {
        var report = String(repeating: "=", count: 80) + "\n"
        report += "STUDENT ANALYSIS SYSTEM - COMPREHENSIVE REPORT\n"
        report += "Generated: \(dateFormatter.string(from: Date()))\n"
        report += String(repeating: "=", count: 80) + "\n\n"
        
        // Executive Summary
        report += "EXECUTIVE SUMMARY\n"
        report += String(repeating: "-", count: 40) + "\n"
        report += "Total Students Analyzed: \(results.totalStudents.formatted())\n"
        report += "Multi-Year Students: \(results.multiYearStudents.formatted())\n"
        report += "Significant Correlations Found: \(results.significantCorrelations.formatted())\n"
        report += "Students Needing Intervention: \(results.interventionCount.formatted())\n"
        report += "Students Ready for Acceleration: \(results.accelerationCount.formatted())\n\n"
        
        // Key Findings
        report += "KEY FINDINGS\n"
        report += String(repeating: "-", count: 40) + "\n"
        
        for finding in results.keyFindings {
            report += "• \(finding)\n"
        }
        report += "\n"
        
        // Correlation Summary
        report += "TOP CORRELATIONS DISCOVERED\n"
        report += String(repeating: "-", count: 40) + "\n"
        
        for correlation in results.topCorrelations.prefix(10) {
            report += String(format: "%@ → %@: r = %.3f (p < %.4f)\n",
                           correlation.source,
                           correlation.target,
                           correlation.value,
                           correlation.pValue)
        }
        report += "\n"
        
        // Validation Results
        if let validation = results.validationMetrics {
            report += "MODEL VALIDATION\n"
            report += String(repeating: "-", count: 40) + "\n"
            report += "Accuracy: \(String(format: "%.2f%%", validation.accuracy * 100))\n"
            report += "Precision: \(String(format: "%.2f%%", validation.precision * 100))\n"
            report += "Recall: \(String(format: "%.2f%%", validation.recall * 100))\n"
            report += "F1 Score: \(String(format: "%.3f", validation.f1Score))\n\n"
        }
        
        report += String(repeating: "=", count: 80) + "\n"
        report += "END OF REPORT\n"
        
        return report
    }
    
    private func generateMarkdownReport(_ results: AnalysisResults) async -> String {
        var markdown = """
        # Student Analysis System Report
        
        **Generated:** \(dateFormatter.string(from: Date()))
        
        ---
        
        ## Executive Summary
        
        | Metric | Value |
        |--------|-------|
        | Total Students Analyzed | \(results.totalStudents.formatted()) |
        | Multi-Year Students | \(results.multiYearStudents.formatted()) |
        | Significant Correlations | \(results.significantCorrelations.formatted()) |
        | Intervention Needed | \(results.interventionCount.formatted()) |
        | Acceleration Ready | \(results.accelerationCount.formatted()) |
        
        ## Key Findings
        
        """
        
        for finding in results.keyFindings {
            markdown += "- \(finding)\n"
        }
        
        markdown += """
        
        ## Top Component Correlations
        
        | Source | Target | Correlation | P-Value | Sample Size |
        |--------|--------|------------|---------|-------------|
        """
        
        for correlation in results.topCorrelations.prefix(15) {
            markdown += "| \(correlation.source) | \(correlation.target) | "
            markdown += String(format: "%.3f | %.4f | %d |\n",
                             correlation.value,
                             correlation.pValue,
                             correlation.sampleSize)
        }
        
        if let validation = results.validationMetrics {
            markdown += """
            
            ## Model Validation
            
            ### Performance Metrics
            - **Accuracy:** \(String(format: "%.2f%%", validation.accuracy * 100))
            - **Precision:** \(String(format: "%.2f%%", validation.precision * 100))
            - **Recall:** \(String(format: "%.2f%%", validation.recall * 100))
            - **F1 Score:** \(String(format: "%.3f", validation.f1Score))
            
            ### Confusion Matrix
            |  | Predicted Positive | Predicted Negative |
            |--|-------------------|-------------------|
            | **Actual Positive** | \(validation.confusionMatrix.truePositives) | \(validation.confusionMatrix.falseNegatives) |
            | **Actual Negative** | \(validation.confusionMatrix.falsePositives) | \(validation.confusionMatrix.trueNegatives) |
            
            """
        }
        
        return markdown
    }
    
    private func generateHTMLReport(_ results: AnalysisResults) async -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Student Analysis Report</title>
            <style>
                body { font-family: -apple-system, Arial, sans-serif; margin: 40px; }
                h1 { color: #333; }
                table { border-collapse: collapse; width: 100%; margin: 20px 0; }
                th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
                th { background-color: #f2f2f2; }
                .metric { font-size: 24px; font-weight: bold; color: #2196F3; }
            </style>
        </head>
        <body>
            <h1>Student Analysis System Report</h1>
            <p>Generated: \(dateFormatter.string(from: Date()))</p>
            
            <h2>Summary</h2>
            <div>
                <span class="metric">\(results.totalStudents)</span> Students Analyzed<br>
                <span class="metric">\(results.significantCorrelations)</span> Significant Correlations<br>
                <span class="metric">\(results.interventionCount)</span> Need Intervention<br>
                <span class="metric">\(results.accelerationCount)</span> Ready for Acceleration
            </div>
            
            <h2>Top Correlations</h2>
            <table>
                <tr>
                    <th>Source</th>
                    <th>Target</th>
                    <th>Correlation</th>
                    <th>Confidence</th>
                </tr>
                \(results.topCorrelations.prefix(20).map { correlation in
                    """
                    <tr>
                        <td>\(correlation.source)</td>
                        <td>\(correlation.target)</td>
                        <td>\(String(format: "%.3f", correlation.value))</td>
                        <td>\(String(format: "%.1f%%", (1 - correlation.pValue) * 100))</td>
                    </tr>
                    """
                }.joined())
            </table>
        </body>
        </html>
        """
    }
}

public enum ReportFormat {
    case text
    case markdown
    case html
}

public struct AnalysisResults {
    public let totalStudents: Int
    public let multiYearStudents: Int
    public let significantCorrelations: Int
    public let interventionCount: Int
    public let accelerationCount: Int
    public let keyFindings: [String]
    public let topCorrelations: [CorrelationSummary]
    public let validationMetrics: ValidationResults?
    
    public struct CorrelationSummary {
        public let source: String
        public let target: String
        public let value: Double
        public let pValue: Double
        public let sampleSize: Int
    }
}