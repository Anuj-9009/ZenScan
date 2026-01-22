import Foundation

/// Agent responsible for finding duplicate files with improved performance
actor DuplicateAgent {
    private let fileManager = FileManager.default
    
    /// Scan locations for duplicates
    private var scanLocations: [URL] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Pictures"),
        ]
    }
    
    /// Minimum file size to consider (skip tiny files)
    private let minFileSize: Int64 = 10240 // 10 KB
    
    /// Maximum files to scan per directory
    private let maxFilesPerDir = 500
    
    /// Scan for duplicate files with improved async handling
    func scanForDuplicates(progress: @escaping (Double, String) -> Void) async -> [DuplicateGroup] {
        // Update progress on main thread
        await MainActor.run {
            progress(0, "Indexing files...")
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var filesBySize: [Int64: [URL]] = [:]
                
                // Phase 1: Group files by size (fast filter)
                let totalLocations = Double(self.scanLocations.count)
                
                for (index, location) in self.scanLocations.enumerated() {
                    DispatchQueue.main.async {
                        progress(Double(index) / totalLocations * 0.3, "Scanning \(location.lastPathComponent)...")
                    }
                    self.indexFilesSync(at: location, into: &filesBySize)
                }
                
                // Filter to only sizes with multiple files
                let potentialDuplicates = filesBySize.filter { $0.value.count > 1 }
                
                // Phase 2: Calculate hashes for potential duplicates
                DispatchQueue.main.async {
                    progress(0.3, "Calculating checksums...")
                }
                
                var duplicateGroups: [DuplicateGroup] = []
                let totalGroups = Double(max(potentialDuplicates.count, 1))
                var processed = 0
                
                for (size, urls) in potentialDuplicates {
                    autoreleasepool {
                        processed += 1
                        
                        if processed % 10 == 0 { // Update every 10 groups
                            DispatchQueue.main.async {
                                progress(0.3 + (Double(processed) / totalGroups * 0.7), "Comparing files...")
                            }
                        }
                        
                        // Group by hash
                        var hashGroups: [String: [URL]] = [:]
                        for url in urls {
                            if let hash = FileHasher.quickHash(for: url) {
                                hashGroups[hash, default: []].append(url)
                            }
                        }
                        
                        // Create duplicate groups
                        for (hash, matchingUrls) in hashGroups where matchingUrls.count > 1 {
                            var files = matchingUrls.enumerated().map { index, url -> DuplicateFile in
                                let attributes = try? self.fileManager.attributesOfItem(atPath: url.path)
                                let modDate = attributes?[.modificationDate] as? Date
                                return DuplicateFile(
                                    path: url,
                                    size: size,
                                    modificationDate: modDate,
                                    isOriginal: false
                                )
                            }
                            
                            // Mark oldest as original
                            files.sort { ($0.modificationDate ?? Date.distantFuture) < ($1.modificationDate ?? Date.distantFuture) }
                            if !files.isEmpty {
                                files[0].isOriginal = true
                            }
                            
                            duplicateGroups.append(DuplicateGroup(
                                hash: hash,
                                size: size,
                                files: files
                            ))
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    progress(1.0, "Found \(duplicateGroups.count) duplicate groups")
                }
                
                continuation.resume(returning: duplicateGroups.sorted { $0.wastedSpace > $1.wastedSpace })
            }
        }
    }
    
    /// Index files by size in a directory (synchronous)
    private func indexFilesSync(at url: URL, into sizeMap: inout [Int64: [URL]]) {
        guard fileManager.isReadableFile(atPath: url.path) else { return }
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return }
        
        var fileCount = 0
        for case let fileURL as URL in enumerator {
            autoreleasepool {
                if fileCount >= maxFilesPerDir { 
                    enumerator.skipDescendants()
                    return
                }
                
                guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                      values.isDirectory != true else { return }
                
                let size = Int64(values.fileSize ?? 0)
                if size >= minFileSize {
                    sizeMap[size, default: []].append(fileURL)
                    fileCount += 1
                }
            }
        }
    }
    
    /// Delete selected duplicate files
    func deleteFiles(_ files: [DuplicateFile]) async -> (deleted: Int, failed: Int) {
        var deleted = 0
        var failed = 0
        
        for file in files where !file.isOriginal {
            do {
                try fileManager.trashItem(at: file.path, resultingItemURL: nil)
                deleted += 1
            } catch {
                failed += 1
            }
        }
        
        return (deleted, failed)
    }
}
