import Foundation

/// Agent for Download folder management
actor DownloadAgent {
    private let fileManager = FileManager.default
    private let downloadsURL: URL
    
    init() {
        downloadsURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
    }
    
    /// Scan downloads folder
    func scanDownloads() async -> [DownloadItem] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: downloadsURL,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey]
        ) else {
            return []
        }
        
        var items: [DownloadItem] = []
        
        for url in contents {
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey]) else {
                continue
            }
            
            let size: Int64
            if values.isDirectory == true {
                size = await calculateDirectorySize(at: url)
            } else {
                size = Int64(values.fileSize ?? 0)
            }
            
            items.append(DownloadItem(
                path: url,
                name: url.lastPathComponent,
                size: size,
                modificationDate: values.contentModificationDate ?? Date(),
                isDirectory: values.isDirectory ?? false
            ))
        }
        
        return items.sorted { $0.modificationDate > $1.modificationDate }
    }
    
    /// Get items older than specified days
    func getOldItems(olderThan days: Int) async -> [DownloadItem] {
        let items = await scanDownloads()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return items.filter { $0.modificationDate < cutoffDate }
    }
    
    /// Delete items
    func deleteItems(_ items: [DownloadItem]) async -> (deleted: Int, failed: Int) {
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
    
    private func calculateDirectorySize(at url: URL) async -> Int64 {
        var size: Int64 = 0
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                size += Int64(fileSize)
            }
        }
        return size
    }
}

/// Download item model
struct DownloadItem: Identifiable, Hashable {
    let id = UUID()
    let path: URL
    let name: String
    let size: Int64
    let modificationDate: Date
    let isDirectory: Bool
    var isSelected: Bool = false
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: modificationDate, relativeTo: Date())
    }
    
    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: modificationDate, to: Date()).day ?? 0
    }
    
    var icon: String {
        if isDirectory {
            return "folder.fill"
        }
        
        let ext = path.pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.fill"
        case "zip", "rar", "7z", "tar", "gz": return "archivebox.fill"
        case "dmg", "pkg": return "externaldrive.fill"
        case "jpg", "jpeg", "png", "gif", "heic": return "photo.fill"
        case "mp4", "mov", "avi", "mkv": return "film.fill"
        case "mp3", "wav", "aac", "m4a": return "music.note"
        case "app": return "app.fill"
        default: return "doc.fill"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DownloadItem, rhs: DownloadItem) -> Bool {
        lhs.id == rhs.id
    }
}
