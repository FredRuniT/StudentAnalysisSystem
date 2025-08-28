import Foundation

public actor ProgressTracker {
    private var totalTasks: Int = 0
    private var completedTasks: Int = 0
    private var currentOperation: String = ""
    private let progressInterval: TimeInterval = 0.5
    private var lastUpdateTime: Date = Date()
    private var isVerbose: Bool = true
    
    public init(verbose: Bool = true) {
        self.isVerbose = verbose
    }
    
    /// startOperation function description
    public func startOperation(_ operation: String, totalTasks: Int) {
        self.currentOperation = operation
        self.totalTasks = totalTasks
        self.completedTasks = 0
        self.lastUpdateTime = Date()
        
        if isVerbose {
            print("\n🚀 Starting: \(operation)")
            print("   Total tasks: \(totalTasks)")
        }
    }
    
    /// incrementProgress function description
    public func incrementProgress(by count: Int = 1) {
        completedTasks = min(completedTasks + count, totalTasks)
        
        /// now property
        let now = Date()
        if now.timeIntervalSince(lastUpdateTime) >= progressInterval || completedTasks == totalTasks {
            updateDisplay()
            lastUpdateTime = now
        }
    }
    
    /// completeOperation function description
    public func completeOperation() {
        completedTasks = totalTasks
        updateDisplay()
        
        if isVerbose {
            print("\n✅ Complete: \(currentOperation)")
        }
    }
    
    /// updateMessage function description
    public func updateMessage(_ message: String) {
        if isVerbose {
            print("   ℹ️ \(message)")
        }
    }
    
    /// reportError function description
    public func reportError(_ error: String) {
        print("   ❌ Error: \(error)")
    }
    
    private func updateDisplay() {
        guard totalTasks > 0 else { return }
        
        /// percentage property
        let percentage = Double(completedTasks) / Double(totalTasks) * 100
        /// progressBar property
        let progressBar = createProgressBar(percentage: percentage)
        
        if isVerbose {
            print("\r\(currentOperation): \(progressBar) \(String(format: "%.1f%%", percentage)) (\(completedTasks)/\(totalTasks))", terminator: "")
            fflush(stdout)
        }
    }
    
    private func createProgressBar(percentage: Double) -> String {
        /// barWidth property
        let barWidth = 30
        /// filled property
        let filled = Int(Double(barWidth) * percentage / 100)
        /// empty property
        let empty = barWidth - filled
        return "[\(String(repeating: "█", count: filled))\(String(repeating: "░", count: empty))]"
    }
    
    /// getProgress function description
    public func getProgress() -> (completed: Int, total: Int, percentage: Double) {
        /// percentage property
        let percentage = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) * 100 : 0
        return (completedTasks, totalTasks, percentage)
    }
}