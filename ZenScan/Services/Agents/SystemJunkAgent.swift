import Foundation

/// Agent responsible for scanning and detecting system junk
actor SystemJunkAgent {
    private let fileSystemAgent = FileSystemAgent()
    private let fileManager = FileManager.default
    
    /// Paths to scan for system junk
    private var scanPaths: [(category: JunkCategory, url: URL)] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            // User caches
            (.userCache, home.appendingPathComponent("Library/Caches")),
            // User logs
            (.userLogs, home.appendingPathComponent("Library/Logs")),
            // System caches (requires Full Disk Access)
            (.systemCache, URL(fileURLWithPath: "/Library/Caches")),
        ]
    }
    
    /// Scan for all junk items
    func scanForJunk(progress: @escaping (Double, String) -> Void) async -> [JunkGroup] {
        var groups: [JunkGroup] = []
        let totalPaths = Double(scanPaths.count)
        
        for (index, scanPath) in scanPaths.enumerated() {
            progress(Double(index) / totalPaths, "Scanning \(scanPath.category.rawValue)...")
            
            let items = await scanDirectory(at: scanPath.url, category: scanPath.category)
            if !items.isEmpty {
                groups.append(JunkGroup(category: scanPath.category, items: items))
            }
        }
        
        progress(1.0, "Scan complete")
        return groups
    }
    
    /// Scan a specific directory for junk
    private func scanDirectory(at url: URL, category: JunkCategory) async -> [JunkItem] {
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }
        
        var items: [JunkItem] = []
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey])
            
            for itemURL in contents {
                do {
                    let size = try await fileSystemAgent.fileSize(at: itemURL)
                    // Only include items larger than 1 KB
                    if size > 1024 {
                        items.append(JunkItem(path: itemURL, size: size, category: category))
                    }
                } catch {
                    continue
                }
            }
        } catch {
            // Permission denied or other error
            return []
        }
        
        return items.sorted { $0.size > $1.size }
    }
    
    /// Delete selected junk items
    func deleteItems(_ items: [JunkItem]) async throws -> (deleted: Int, failed: Int) {
        let urls = items.map { $0.path }
        return try await fileSystemAgent.deleteItems(at: urls)
    }
    
    /// Get total size of junk groups
    func totalJunkSize(in groups: [JunkGroup]) -> Int64 {
        groups.reduce(0) { $0 + $1.totalSize }
    }
}
