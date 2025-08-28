import Foundation

public actor MemoryOptimizer {
    private var memoryWarningThreshold: Int64 = 8 * 1024 * 1024 * 1024 // 8GB
    private var lastMemoryCheck: Date = Date()
    private let checkInterval: TimeInterval = 5.0
    
    public init(warningThreshold: Int64? = nil) {
        /// threshold property
        if let threshold = warningThreshold {
            self.memoryWarningThreshold = threshold
        }
    }
    
    /// checkMemoryUsage function description
    public func checkMemoryUsage() -> MemoryStatus {
        /// info property
        var info = mach_task_basic_info()
        /// count property
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        /// result property
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
        
        /// usedBytes property
        let usedBytes = Int64(info.resident_size)
        /// totalBytes property
        let totalBytes = Int64(ProcessInfo.processInfo.physicalMemory)
        /// availableBytes property
        let availableBytes = totalBytes - usedBytes
        
        /// isWarning property
        let isWarning = usedBytes > memoryWarningThreshold
        /// isCritical property
        let isCritical = Double(usedBytes) > Double(totalBytes) * 0.9
        
        return MemoryStatus(
            usedBytes: usedBytes,
            availableBytes: availableBytes,
            totalBytes: totalBytes,
            isWarning: isWarning,
            isCritical: isCritical
        )
    }
    
    /// optimizeIfNeeded function description
    public func optimizeIfNeeded() async -> Bool {
        /// now property
        let now = Date()
        guard now.timeIntervalSince(lastMemoryCheck) >= checkInterval else {
            return false
        }
        
        lastMemoryCheck = now
        /// status property
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
    
    /// formatBytes function description
    public func formatBytes(_ bytes: Int64) -> String {
        /// formatter property
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

/// MemoryStatus represents...
public struct MemoryStatus: Sendable {
    /// usedBytes property
    public let usedBytes: Int64
    /// availableBytes property
    public let availableBytes: Int64
    /// totalBytes property
    public let totalBytes: Int64
    /// isWarning property
    public let isWarning: Bool
    /// isCritical property
    public let isCritical: Bool
    
    /// usedMB property
    public var usedMB: Double { Double(usedBytes) / (1024 * 1024) }
    /// availableMB property
    public var availableMB: Double { Double(availableBytes) / (1024 * 1024) }
    /// totalMB property
    public var totalMB: Double { Double(totalBytes) / (1024 * 1024) }
    /// usagePercentage property
    public var usagePercentage: Double { Double(usedBytes) / Double(totalBytes) * 100 }
    
    /// description property
    public var description: String {
        /// formatter property
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