import Foundation

/// Agent responsible for finding large files on disk with improved performance
actor LargeFilesAgent {
    private let fileSystemAgent = FileSystemAgent()
    private let fileManager = FileManager.default
    
    /// Maximum number of files to return
    private let maxResults = 200
    
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
    
    /// Scan for large files above threshold with improved async handling
    func scanForLargeFiles(
        threshold: Int64 = 104857600, // 100 MB default
        progress: @escaping (Double, String) -> Void
    ) async -> [LargeFile] {
        
        await MainActor.run {
            progress(0, "Starting scan...")
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var largeFiles: [LargeFile] = []
                let totalLocations = Double(self.scanLocations.count)
                
                for (index, location) in self.scanLocations.enumerated() {
                    let folderName = location.lastPathComponent
                    
                    DispatchQueue.main.async {
                        progress(Double(index) / totalLocations, "Scanning \(folderName)...")
                    }
                    
                    let files = self.scanDirectorySync(at: location, threshold: threshold)
                    largeFiles.append(contentsOf: files)
                }
                
                // Sort and limit results
                largeFiles.sort { $0.size > $1.size }
                largeFiles = Array(largeFiles.prefix(self.maxResults))
                
                DispatchQueue.main.async {
                    progress(1.0, "Found \(largeFiles.count) large files")
                }
                
                continuation.resume(returning: largeFiles)
            }
        }
    }
    
    /// Scan a specific directory for large files (synchronous)
    private func scanDirectorySync(at url: URL, threshold: Int64) -> [LargeFile] {
        var results: [LargeFile] = []
        
        guard fileManager.isReadableFile(atPath: url.path) else {
            return results
        }
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true } // Continue on errors
        ) else {
            return results
        }
        
        var fileCount = 0
        let maxFilesToScan = 5000 // Limit per directory
        
        for case let fileURL as URL in enumerator {
            autoreleasepool {
                fileCount += 1
                if fileCount > maxFilesToScan {
                    enumerator.skipDescendants()
                    return
                }
                
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey]),
                      resourceValues.isDirectory != true else { return }
                
                let size = Int64(resourceValues.fileSize ?? 0)
                if size >= threshold {
                    results.append(LargeFile(
                        path: fileURL,
                        size: size,
                        modificationDate: resourceValues.contentModificationDate
                    ))
                }
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
