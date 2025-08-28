import Foundation

public actor MemoryOptimizer {
    private var memoryWarningThreshold: Int64 = 8 * 1024 * 1024 * 1024 // 8GB
    private var lastMemoryCheck: Date = Date()
    private let checkInterval: TimeInterval = 5.0
    
    public init(warningThreshold: Int64? = nil) {
        if let threshold = warningThreshold {
            self.memoryWarningThreshold = threshold
        }
    }
    
    public func checkMemoryUsage() -> MemoryStatus {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return MemoryStatus(
                usedBytes: 0,
                availableBytes: 0,
                totalBytes: 0,
                isWarning: false,
                isCritical: false
            )
        }
        
        let usedBytes = Int64(info.resident_size)
        let totalBytes = Int64(ProcessInfo.processInfo.physicalMemory)
        let availableBytes = totalBytes - usedBytes
        
        let isWarning = usedBytes > memoryWarningThreshold
        let isCritical = Double(usedBytes) > Double(totalBytes) * 0.9
        
        return MemoryStatus(
            usedBytes: usedBytes,
            availableBytes: availableBytes,
            totalBytes: totalBytes,
            isWarning: isWarning,
            isCritical: isCritical
        )
    }
    
    public func optimizeIfNeeded() async -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastMemoryCheck) >= checkInterval else {
            return false
        }
        
        lastMemoryCheck = now
        let status = checkMemoryUsage()
        
        if status.isCritical {
            await performAggressiveOptimization()
            return true
        } else if status.isWarning {
            await performSoftOptimization()
            return true
        }
        
        return false
    }
    
    private func performSoftOptimization() async {
        // Request garbage collection
        autoreleasepool {
            // Force autorelease pool drain
        }
    }
    
    private func performAggressiveOptimization() async {
        // More aggressive memory recovery
        autoreleasepool {
            // Clear caches
            URLCache.shared.removeAllCachedResponses()
            
            // Force autorelease pool drain
        }
    }
    
    public func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

public struct MemoryStatus: Sendable {
    public let usedBytes: Int64
    public let availableBytes: Int64
    public let totalBytes: Int64
    public let isWarning: Bool
    public let isCritical: Bool
    
    public var usedMB: Double { Double(usedBytes) / (1024 * 1024) }
    public var availableMB: Double { Double(availableBytes) / (1024 * 1024) }
    public var totalMB: Double { Double(totalBytes) / (1024 * 1024) }
    public var usagePercentage: Double { Double(usedBytes) / Double(totalBytes) * 100 }
    
    public var description: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        
        return """
        Memory Status:
        - Used: \(formatter.string(fromByteCount: usedBytes)) (\(String(format: "%.1f%%", usagePercentage)))
        - Available: \(formatter.string(fromByteCount: availableBytes))
        - Total: \(formatter.string(fromByteCount: totalBytes))
        - Status: \(isCritical ? "CRITICAL" : isWarning ? "WARNING" : "OK")
        """
    }
}