import Foundation

/// Agent for memory management and RAM cleaning
actor MemoryAgent {
    /// Get current memory usage statistics
    func getMemoryStats() -> MemoryStats {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let host = mach_host_self()
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        
        let pageSize = Int64(vm_kernel_page_size)
        let totalMemory = Int64(ProcessInfo.processInfo.physicalMemory)
        
        if result == KERN_SUCCESS {
            let activeMemory = Int64(stats.active_count) * pageSize
            let wiredMemory = Int64(stats.wire_count) * pageSize
            let compressedMemory = Int64(stats.compressor_page_count) * pageSize
            let inactiveMemory = Int64(stats.inactive_count) * pageSize
            let freeMemory = Int64(stats.free_count) * pageSize
            
            return MemoryStats(
                total: totalMemory,
                active: activeMemory,
                wired: wiredMemory,
                compressed: compressedMemory,
                inactive: inactiveMemory,
                free: freeMemory
            )
        }
        
        return MemoryStats(
            total: totalMemory,
            active: 0,
            wired: 0,
            compressed: 0,
            inactive: 0,
            free: 0
        )
    }
    
    /// Purge inactive memory (requires admin privileges)
    func purgeInactiveMemory() async -> Bool {
        // Use the purge command which requires admin
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/purge")
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// Get memory pressure level
    func getMemoryPressure() -> MemoryPressure {
        let stats = getMemoryStats()
        let usedRatio = Double(stats.used) / Double(stats.total)
        
        if usedRatio > 0.9 {
            return .critical
        } else if usedRatio > 0.75 {
            return .warning
        } else {
            return .normal
        }
    }
}

/// Memory statistics
struct MemoryStats {
    let total: Int64
    let active: Int64
    let wired: Int64
    let compressed: Int64
    let inactive: Int64
    let free: Int64
    
    var used: Int64 {
        active + wired + compressed
    }
    
    var available: Int64 {
        inactive + free
    }
    
    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: total, countStyle: .memory)
    }
    
    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: used, countStyle: .memory)
    }
    
    var formattedAvailable: String {
        ByteCountFormatter.string(fromByteCount: available, countStyle: .memory)
    }
    
    var formattedInactive: String {
        ByteCountFormatter.string(fromByteCount: inactive, countStyle: .memory)
    }
    
    var usagePercent: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }
}

/// Memory pressure levels
enum MemoryPressure {
    case normal
    case warning
    case critical
    
    var color: String {
        switch self {
        case .normal: return "emeraldGreen"
        case .warning: return "orange"
        case .critical: return "red"
        }
    }
}
