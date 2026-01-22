import Foundation

/// Agent responsible for finding large files on disk
actor LargeFilesAgent {
    private let fileSystemAgent = FileSystemAgent()
    private let fileManager = FileManager.default
    
    /// Default scan locations
    private var scanLocations: [URL] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Movies"),
            home.appendingPathComponent("Music"),
            home.appendingPathComponent("Pictures"),
        ]
    }
    
    /// Scan for large files above threshold
    func scanForLargeFiles(
        threshold: Int64 = 104857600, // 100 MB default
        progress: @escaping (Double, String) -> Void
    ) async -> [LargeFile] {
        var largeFiles: [LargeFile] = []
        let totalLocations = Double(scanLocations.count)
        
        for (index, location) in scanLocations.enumerated() {
            let folderName = location.lastPathComponent
            progress(Double(index) / totalLocations, "Scanning \(folderName)...")
            
            let files = await scanDirectory(at: location, threshold: threshold)
            largeFiles.append(contentsOf: files)
        }
        
        progress(1.0, "Found \(largeFiles.count) large files")
        return largeFiles.sorted { $0.size > $1.size }
    }
    
    /// Scan a specific directory for large files
    private func scanDirectory(at url: URL, threshold: Int64) async -> [LargeFile] {
        var results: [LargeFile] = []
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: nil
        ) else {
            return results
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey])
                
                // Skip directories
                if resourceValues.isDirectory == true {
                    continue
                }
                
                let size = Int64(resourceValues.fileSize ?? 0)
                if size >= threshold {
                    results.append(LargeFile(
                        path: fileURL,
                        size: size,
                        modificationDate: resourceValues.contentModificationDate
                    ))
                }
            } catch {
                continue
            }
        }
        
        return results
    }
    
    /// Delete selected large files (move to trash)
    func deleteFiles(_ files: [LargeFile]) async -> (deleted: Int, failed: Int) {
        var deleted = 0
        var failed = 0
        
        for file in files {
            do {
                try fileManager.trashItem(at: file.path, resultingItemURL: nil)
                deleted += 1
            } catch {
                failed += 1
            }
        }
        
        return (deleted, failed)
    }
    
    /// Get total size of files
    func totalSize(of files: [LargeFile]) -> Int64 {
        files.reduce(0) { $0 + $1.size }
    }
}
