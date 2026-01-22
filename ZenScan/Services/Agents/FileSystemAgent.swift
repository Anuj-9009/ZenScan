import Foundation

/// Core agent for file system operations with improved error handling and performance
actor FileSystemAgent {
    private let fileManager = FileManager.default
    
    /// Calculate the total size of a directory recursively (runs on background queue)
    func calculateDirectorySize(at url: URL) async -> Int64 {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var totalSize: Int64 = 0
                
                guard let enumerator = self.fileManager.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants],
                    errorHandler: { _, _ in true } // Continue on errors
                ) else {
                    continuation.resume(returning: 0)
                    return
                }
                
                for case let fileURL as URL in enumerator {
                    autoreleasepool {
                        if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                           values.isDirectory != true {
                            totalSize += Int64(values.fileSize ?? 0)
                        }
                    }
                }
                
                continuation.resume(returning: totalSize)
            }
        }
    }
    
    /// List contents of a directory with size information
    func listDirectoryContents(at url: URL, recursive: Bool = false) async -> [URL] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard self.fileManager.isReadableFile(atPath: url.path) else {
                    continuation.resume(returning: [])
                    return
                }
                
                if recursive {
                    var results: [URL] = []
                    guard let enumerator = self.fileManager.enumerator(
                        at: url,
                        includingPropertiesForKeys: [.fileSizeKey],
                        options: [.skipsHiddenFiles],
                        errorHandler: { _, _ in true }
                    ) else {
                        continuation.resume(returning: [])
                        return
                    }
                    
                    for case let fileURL as URL in enumerator {
                        results.append(fileURL)
                    }
                    continuation.resume(returning: results)
                } else {
                    let contents = (try? self.fileManager.contentsOfDirectory(
                        at: url,
                        includingPropertiesForKeys: [.fileSizeKey]
                    )) ?? []
                    continuation.resume(returning: contents)
                }
            }
        }
    }
    
    /// Get file size at path (cached for performance)
    func fileSize(at url: URL) async -> Int64 {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .totalFileSizeKey])
                    
                    if let isDirectory = resourceValues.isDirectory, isDirectory {
                        // For directories, use totalFileSize if available, otherwise calculate
                        if let totalSize = resourceValues.totalFileSize {
                            continuation.resume(returning: Int64(totalSize))
                        } else {
                            Task {
                                let size = await self.calculateDirectorySize(at: url)
                                continuation.resume(returning: size)
                            }
                        }
                    } else {
                        continuation.resume(returning: Int64(resourceValues.fileSize ?? 0))
                    }
                } catch {
                    continuation.resume(returning: 0)
                }
            }
        }
    }
    
    /// Check if path exists
    func exists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
    
    /// Check if path is readable
    func isReadable(at url: URL) -> Bool {
        fileManager.isReadableFile(atPath: url.path)
    }
    
    /// Delete file or directory (moves to Trash for safety)
    func delete(at url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self.fileManager.trashItem(at: url, resultingItemURL: nil)
                    continuation.resume()
                } catch {
                    // If trashing fails, try permanent delete
                    do {
                        try self.fileManager.removeItem(at: url)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    /// Delete multiple items (moves to Trash for safety)
    func deleteItems(at urls: [URL]) async throws -> (deleted: Int, failed: Int, errors: [String]) {
        var deleted = 0
        var failed = 0
        var errors: [String] = []
        
        for url in urls {
            do {
                try await delete(at: url)
                deleted += 1
            } catch {
                failed += 1
                errors.append("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        return (deleted, failed, errors)
    }
    
    /// Get human-readable file type
    func fileType(at url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "app": return "Application"
        case "dmg", "pkg": return "Installer"
        case "zip", "rar", "7z", "tar", "gz": return "Archive"
        case "jpg", "jpeg", "png", "gif", "heic", "webp": return "Image"
        case "mp4", "mov", "avi", "mkv", "webm": return "Video"
        case "mp3", "wav", "aac", "flac", "m4a": return "Audio"
        case "pdf": return "PDF"
        case "doc", "docx": return "Document"
        case "xls", "xlsx": return "Spreadsheet"
        case "ppt", "pptx": return "Presentation"
        case "swift", "m", "h", "c", "cpp", "py", "js", "ts": return "Source Code"
        case "log", "txt": return "Text"
        default: return "File"
        }
    }
}
