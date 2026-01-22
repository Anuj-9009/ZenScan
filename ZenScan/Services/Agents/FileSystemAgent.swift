import Foundation

/// Core agent for file system operations
actor FileSystemAgent {
    private let fileManager = FileManager.default
    
    /// Calculate the total size of a directory recursively
    func calculateDirectorySize(at url: URL) async throws -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                if let isDirectory = resourceValues.isDirectory, !isDirectory {
                    totalSize += Int64(resourceValues.fileSize ?? 0)
                }
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    /// List contents of a directory with size information
    func listDirectoryContents(at url: URL, recursive: Bool = false) async throws -> [URL] {
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }
        
        if recursive {
            var results: [URL] = []
            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles],
                errorHandler: nil
            ) else {
                return []
            }
            
            for case let fileURL as URL in enumerator {
                results.append(fileURL)
            }
            return results
        } else {
            return try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey])
        }
    }
    
    /// Get file size at path
    func fileSize(at url: URL) async throws -> Int64 {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
        
        if let isDirectory = resourceValues.isDirectory, isDirectory {
            return try await calculateDirectorySize(at: url)
        }
        
        return Int64(resourceValues.fileSize ?? 0)
    }
    
    /// Check if path exists
    func exists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
    
    /// Delete file or directory
    func delete(at url: URL) async throws {
        try fileManager.removeItem(at: url)
    }
    
    /// Delete multiple items
    func deleteItems(at urls: [URL]) async throws -> (deleted: Int, failed: Int) {
        var deleted = 0
        var failed = 0
        
        for url in urls {
            do {
                try fileManager.removeItem(at: url)
                deleted += 1
            } catch {
                failed += 1
            }
        }
        
        return (deleted, failed)
    }
}
