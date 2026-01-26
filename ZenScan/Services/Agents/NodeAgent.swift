import Foundation

/// Agent for Node.js/npm/yarn cache cleanup
actor NodeAgent {
    private let fileManager = FileManager.default
    
    /// Common Node.js cache locations
    private var cachePaths: [(name: String, path: URL)] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            ("npm cache", home.appendingPathComponent(".npm/_cacache")),
            ("npm logs", home.appendingPathComponent(".npm/_logs")),
            ("yarn cache", home.appendingPathComponent(".yarn/cache")),
            ("yarn berry", home.appendingPathComponent(".yarn/berry/cache")),
            ("pnpm store", home.appendingPathComponent(".pnpm-store")),
        ]
    }
    
    /// Check if Node.js is installed
    var isInstalled: Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["node"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// Find all node_modules directories
    func findNodeModules(in searchPaths: [URL]? = nil, progress: @escaping (Double, String) -> Void) async -> [NodeModulesItem] {
        let paths = searchPaths ?? defaultSearchPaths
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var results: [NodeModulesItem] = []
                let totalPaths = Double(max(paths.count, 1))
                
                for (index, searchPath) in paths.enumerated() {
                    DispatchQueue.main.async {
                        progress(Double(index) / totalPaths, "Searching \(searchPath.lastPathComponent)...")
                    }
                    
                    guard let enumerator = self.fileManager.enumerator(
                        at: searchPath,
                        includingPropertiesForKeys: [.isDirectoryKey],
                        options: [.skipsHiddenFiles],
                        errorHandler: { _, _ in true }
                    ) else { continue }
                    
                    var count = 0
                    for case let url as URL in enumerator {
                        count += 1
                        if count > 10000 { break } // Limit search
                        
                        if url.lastPathComponent == "node_modules" {
                            enumerator.skipDescendants()
                            
                            // Calculate size
                            var size: Int64 = 0
                            if let sizeEnumerator = self.fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [], errorHandler: { _, _ in true }) {
                                for case let fileURL as URL in sizeEnumerator {
                                    if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]) {
                                        size += Int64(values.fileSize ?? 0)
                                    }
                                }
                            }
                            
                            results.append(NodeModulesItem(
                                path: url,
                                projectPath: url.deletingLastPathComponent(),
                                size: size
                            ))
                        }
                    }
                }
                
                DispatchQueue.main.async { progress(1.0, "Found \(results.count) node_modules") }
                continuation.resume(returning: results.sorted { $0.size > $1.size })
            }
        }
    }
    
    /// Default search paths
    private var defaultSearchPaths: [URL] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent("Projects"),
            home.appendingPathComponent("Developer"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Desktop"),
        ]
    }
    
    /// Scan package manager caches
    func scanCaches(progress: @escaping (Double, String) -> Void) async -> NodeCacheScanResult {
        await MainActor.run { progress(0, "Scanning Node.js caches...") }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result = NodeCacheScanResult()
                let totalPaths = Double(max(self.cachePaths.count, 1))
                
                for (index, cache) in self.cachePaths.enumerated() {
                    DispatchQueue.main.async {
                        progress(Double(index) / totalPaths, "Checking \(cache.name)...")
                    }
                    
                    if self.fileManager.fileExists(atPath: cache.path.path) {
                        var size: Int64 = 0
                        if let enumerator = self.fileManager.enumerator(at: cache.path, includingPropertiesForKeys: [.fileSizeKey], options: [], errorHandler: { _, _ in true }) {
                            for case let url as URL in enumerator {
                                if let values = try? url.resourceValues(forKeys: [.fileSizeKey]) {
                                    size += Int64(values.fileSize ?? 0)
                                }
                            }
                        }
                        
                        result.caches.append(NodeCacheItem(
                            name: cache.name,
                            path: cache.path,
                            size: size
                        ))
                        result.totalSize += size
                    }
                }
                
                DispatchQueue.main.async { progress(1.0, "Scan complete") }
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Clean selected caches
    func cleanCaches(_ caches: [NodeCacheItem]) async -> (deleted: Int, failed: Int) {
        var deleted = 0
        var failed = 0
        
        for cache in caches {
            do {
                try fileManager.trashItem(at: cache.path, resultingItemURL: nil)
                deleted += 1
            } catch {
                failed += 1
            }
        }
        
        return (deleted, failed)
    }
    
    /// Delete node_modules directories
    func deleteNodeModules(_ items: [NodeModulesItem]) async -> (deleted: Int, failed: Int) {
        var deleted = 0
        var failed = 0
        
        for item in items {
            do {
                try fileManager.trashItem(at: item.path, resultingItemURL: nil)
                deleted += 1
            } catch {
                failed += 1
            }
        }
        
        return (deleted, failed)
    }
}

/// Node modules item
struct NodeModulesItem: Identifiable {
    let id = UUID()
    let path: URL
    let projectPath: URL
    let size: Int64
    var isSelected: Bool = false
    
    var projectName: String {
        projectPath.lastPathComponent
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

/// Cache scan result
struct NodeCacheScanResult {
    var caches: [NodeCacheItem] = []
    var totalSize: Int64 = 0
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

/// Cache item
struct NodeCacheItem: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let size: Int64
    var isSelected: Bool = false
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
