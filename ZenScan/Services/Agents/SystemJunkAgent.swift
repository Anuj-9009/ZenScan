import Foundation

/// Agent responsible for scanning and detecting system junk with improved performance
actor SystemJunkAgent {
    private let fileSystemAgent = FileSystemAgent()
    private let fileManager = FileManager.default
    
    /// Paths to scan for system junk
    private var scanPaths: [(category: JunkCategory, url: URL)] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            // User caches (most accessible)
            (.userCache, home.appendingPathComponent("Library/Caches")),
            // User logs
            (.userLogs, home.appendingPathComponent("Library/Logs")),
            // Application Support caches
            (.userCache, home.appendingPathComponent("Library/Application Support/CrashReporter")),
            // Xcode derived data
            (.userCache, home.appendingPathComponent("Library/Developer/Xcode/DerivedData")),
            // System caches (requires Full Disk Access)
            (.systemCache, URL(fileURLWithPath: "/Library/Caches")),
        ]
    }
    
    /// Scan for all junk items with improved async handling
    func scanForJunk(progress: @escaping (Double, String) -> Void) async -> [JunkGroup] {
        var groups: [JunkGroup] = []
        let totalPaths = Double(scanPaths.count)
        
        for (index, scanPath) in scanPaths.enumerated() {
            // Update progress on main thread
            let progressValue = Double(index) / totalPaths
            let statusText = "Scanning \(scanPath.category.rawValue)..."
            
            await MainActor.run {
                progress(progressValue, statusText)
            }
            
            let items = await scanDirectory(at: scanPath.url, category: scanPath.category)
            if !items.isEmpty {
                // Merge with existing group of same category or create new
                if let existingIndex = groups.firstIndex(where: { $0.category == scanPath.category }) {
                    var updatedItems = groups[existingIndex].items
                    updatedItems.append(contentsOf: items)
                    groups[existingIndex] = JunkGroup(category: scanPath.category, items: updatedItems)
                } else {
                    groups.append(JunkGroup(category: scanPath.category, items: items))
                }
            }
        }
        
        await MainActor.run {
            progress(1.0, "Scan complete")
        }
        
        return groups
    }
    
    /// Scan a specific directory for junk (runs on background)
    private func scanDirectory(at url: URL, category: JunkCategory) async -> [JunkItem] {
        guard fileManager.fileExists(atPath: url.path),
              fileManager.isReadableFile(atPath: url.path) else {
            return []
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var items: [JunkItem] = []
                
                guard let contents = try? self.fileManager.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey]
                ) else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Process in batches to avoid blocking
                for itemURL in contents.prefix(100) { // Limit to first 100 items per directory
                    autoreleasepool {
                        do {
                            let values = try itemURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .totalFileSizeKey])
                            var size: Int64 = 0
                            
                            if values.isDirectory == true {
                                if let totalSize = values.totalFileSize {
                                    size = Int64(totalSize)
                                } else {
                                    // Quick estimate for directories
                                    size = Int64(values.fileSize ?? 0) * 10
                                }
                            } else {
                                size = Int64(values.fileSize ?? 0)
                            }
                            
                            // Only include items larger than 10 KB
                            if size > 10240 {
                                items.append(JunkItem(path: itemURL, size: size, category: category))
                            }
                        } catch {
                            // Skip items we can't read
                        }
                    }
                }
                
                // Sort by size descending
                items.sort { $0.size > $1.size }
                
                // Limit to top 50 items
                continuation.resume(returning: Array(items.prefix(50)))
            }
        }
    }
    
    /// Delete selected junk items
    func deleteItems(_ items: [JunkItem]) async throws -> (deleted: Int, failed: Int) {
        let urls = items.map { $0.path }
        let result = try await fileSystemAgent.deleteItems(at: urls)
        return (result.deleted, result.failed)
    }
    
    /// Get total size of junk groups
    func totalJunkSize(in groups: [JunkGroup]) -> Int64 {
        groups.reduce(0) { $0 + $1.totalSize }
    }
}
