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
    
    public func incrementProgress(by count: Int = 1) {
        completedTasks = min(completedTasks + count, totalTasks)
        
        let now = Date()
        if now.timeIntervalSince(lastUpdateTime) >= progressInterval || completedTasks == totalTasks {
            updateDisplay()
            lastUpdateTime = now
        }
    }
    
    public func completeOperation() {
        completedTasks = totalTasks
        updateDisplay()
        
        if isVerbose {
            print("\n✅ Complete: \(currentOperation)")
        }
    }
    
    public func updateMessage(_ message: String) {
        if isVerbose {
            print("   ℹ️ \(message)")
        }
    }
    
    public func reportError(_ error: String) {
        print("   ❌ Error: \(error)")
    }
    
    private func updateDisplay() {
        guard totalTasks > 0 else { return }
        
        let percentage = Double(completedTasks) / Double(totalTasks) * 100
        let progressBar = createProgressBar(percentage: percentage)
        
        if isVerbose {
            print("\r\(currentOperation): \(progressBar) \(String(format: "%.1f%%", percentage)) (\(completedTasks)/\(totalTasks))", terminator: "")
            fflush(stdout)
        }
    }
    
    private func createProgressBar(percentage: Double) -> String {
        let barWidth = 30
        let filled = Int(Double(barWidth) * percentage / 100)
        let empty = barWidth - filled
        return "[\(String(repeating: "█", count: filled))\(String(repeating: "░", count: empty))]"
    }
    
    public func getProgress() -> (completed: Int, total: Int, percentage: Double) {
        let percentage = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) * 100 : 0
        return (completedTasks, totalTasks, percentage)
    }
}