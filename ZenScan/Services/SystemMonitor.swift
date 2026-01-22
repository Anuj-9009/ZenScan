import Foundation

/// System monitor for RAM, CPU, and Disk usage
@MainActor
class SystemMonitor: ObservableObject {
    @Published var memoryUsed: Int64 = 0
    @Published var memoryTotal: Int64 = 0
    @Published var diskUsed: Int64 = 0
    @Published var diskTotal: Int64 = 0
    @Published var cpuUsage: Double = 0
    
    private var refreshTimer: Timer?
    
    var memoryUsagePercent: Double {
        guard memoryTotal > 0 else { return 0 }
        return Double(memoryUsed) / Double(memoryTotal)
    }
    
    var diskUsagePercent: Double {
        guard diskTotal > 0 else { return 0 }
        return Double(diskUsed) / Double(diskTotal)
    }
    
    var formattedMemoryUsage: String {
        let used = ByteCountFormatter.string(fromByteCount: memoryUsed, countStyle: .memory)
        let total = ByteCountFormatter.string(fromByteCount: memoryTotal, countStyle: .memory)
        return "\(used) / \(total)"
    }
    
    var formattedDiskUsage: String {
        let used = ByteCountFormatter.string(fromByteCount: diskUsed, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: diskTotal, countStyle: .file)
        return "\(used) / \(total)"
    }
    
    var formattedMemoryFree: String {
        let free = memoryTotal - memoryUsed
        return ByteCountFormatter.string(fromByteCount: free, countStyle: .memory)
    }
    
    var formattedDiskFree: String {
        let free = diskTotal - diskUsed
        return ByteCountFormatter.string(fromByteCount: free, countStyle: .file)
    }
    
    init() {
        Task {
            await refresh()
        }
    }
    
    func startAutoRefresh(interval: TimeInterval = 5.0) {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }
    
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func refresh() async {
        await fetchMemoryInfo()
        await fetchDiskInfo()
        await fetchCPUUsage()
    }
    
    private func fetchMemoryInfo() async {
        // Get physical memory
        memoryTotal = Int64(ProcessInfo.processInfo.physicalMemory)
        
        // Get memory usage via host_statistics
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let host = mach_host_self()
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let pageSize = Int64(vm_kernel_page_size)
            let activeMemory = Int64(stats.active_count) * pageSize
            let wiredMemory = Int64(stats.wire_count) * pageSize
            let compressedMemory = Int64(stats.compressor_page_count) * pageSize
            
            memoryUsed = activeMemory + wiredMemory + compressedMemory
        }
    }
    
    private func fetchDiskInfo() async {
        let fileManager = FileManager.default
        
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: "/")
            
            if let totalSize = attributes[.systemSize] as? Int64 {
                diskTotal = totalSize
            }
            
            if let freeSize = attributes[.systemFreeSize] as? Int64 {
                diskUsed = diskTotal - freeSize
            }
        } catch {
            // Use fallback values
        }
    }
    
    private func fetchCPUUsage() async {
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0
        
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )
        
        if result == KERN_SUCCESS, let cpuInfo = cpuInfo {
            var totalUsage: Double = 0
            
            for i in 0..<Int(numCPUs) {
                let offset = Int(CPU_STATE_MAX) * i
                let user = Double(cpuInfo[offset + Int(CPU_STATE_USER)])
                let system = Double(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
                let idle = Double(cpuInfo[offset + Int(CPU_STATE_IDLE)])
                let nice = Double(cpuInfo[offset + Int(CPU_STATE_NICE)])
                
                let total = user + system + idle + nice
                if total > 0 {
                    totalUsage += ((user + system + nice) / total) * 100
                }
            }
            
            cpuUsage = totalUsage / Double(numCPUs)
            
            // Deallocate
            let size = Int(numCPUInfo) * MemoryLayout<integer_t>.size
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(size))
        }
    }
}
