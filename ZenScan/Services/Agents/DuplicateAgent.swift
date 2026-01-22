import Foundation

/// Agent responsible for finding duplicate files
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
    private let minFileSize: Int64 = 1024 // 1 KB
    
    /// Scan for duplicate files
    func scanForDuplicates(progress: @escaping (Double, String) -> Void) async -> [DuplicateGroup] {
        var filesBySize: [Int64: [URL]] = [:]
        
        // Phase 1: Group files by size (fast filter)
        progress(0, "Indexing files...")
        let totalLocations = Double(scanLocations.count)
        
        for (index, location) in scanLocations.enumerated() {
            progress(Double(index) / totalLocations * 0.3, "Scanning \(location.lastPathComponent)...")
            await indexFiles(at: location, into: &filesBySize)
        }
        
        // Filter to only sizes with multiple files
        let potentialDuplicates = filesBySize.filter { $0.value.count > 1 }
        
        // Phase 2: Calculate hashes for potential duplicates
        progress(0.3, "Calculating checksums...")
        var duplicateGroups: [DuplicateGroup] = []
        let totalGroups = Double(potentialDuplicates.count)
        var processed = 0
        
        for (size, urls) in potentialDuplicates {
            processed += 1
            progress(0.3 + (Double(processed) / totalGroups * 0.7), "Comparing files...")
            
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
                    let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                    let modDate = attributes?[.modificationDate] as? Date
                    return DuplicateFile(
                        path: url,
                        size: size,
                        modificationDate: modDate,
                        isOriginal: index == 0  // First one is suggested original
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
        
        progress(1.0, "Found \(duplicateGroups.count) duplicate groups")
        return duplicateGroups.sorted { $0.wastedSpace > $1.wastedSpace }
    }
    
    /// Index files by size in a directory
    private func indexFiles(at url: URL, into sizeMap: inout [Int64: [URL]]) async {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: nil
        ) else { return }
        
        for case let fileURL as URL in enumerator {
            do {
                let values = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                if values.isDirectory == true { continue }
                
                let size = Int64(values.fileSize ?? 0)
                if size >= minFileSize {
                    sizeMap[size, default: []].append(fileURL)
                }
            } catch {
                continue
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
