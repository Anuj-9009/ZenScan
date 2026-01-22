import Foundation

/// Represents a large file found during scanning
struct LargeFile: Identifiable, Hashable {
    let id = UUID()
    let path: URL
    let size: Int64
    let modificationDate: Date?
    var isSelected: Bool = false
    
    /// Human-readable file size
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    /// File name
    var name: String {
        path.lastPathComponent
    }
    
    /// File extension
    var fileExtension: String {
        path.pathExtension.lowercased()
    }
    
    /// Parent folder path
    var parentPath: String {
        path.deletingLastPathComponent().path
    }
    
    /// File type icon
    var icon: String {
        switch fileExtension {
        case "mp4", "mov", "avi", "mkv": return "film"
        case "mp3", "wav", "aac", "flac": return "music.note"
        case "jpg", "jpeg", "png", "gif", "heic": return "photo"
        case "pdf": return "doc.text"
        case "zip", "rar", "7z", "tar", "gz": return "archivebox"
        case "dmg", "iso": return "opticaldisc"
        case "app": return "app"
        default: return "doc"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LargeFile, rhs: LargeFile) -> Bool {
        lhs.id == rhs.id
    }
}

/// Size threshold options for large file scanning
enum FileSizeThreshold: Int64, CaseIterable, Identifiable {
    case mb50 = 52428800      // 50 MB
    case mb100 = 104857600    // 100 MB
    case mb500 = 524288000    // 500 MB
    case gb1 = 1073741824     // 1 GB
    
    var id: Int64 { rawValue }
    
    var displayName: String {
        switch self {
        case .mb50: return "> 50 MB"
        case .mb100: return "> 100 MB"
        case .mb500: return "> 500 MB"
        case .gb1: return "> 1 GB"
        }
    }
}
