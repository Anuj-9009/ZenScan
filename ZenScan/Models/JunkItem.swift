import Foundation

/// Categories for different types of system junk
enum JunkCategory: String, CaseIterable, Identifiable {
    case systemCache = "System Cache"
    case userCache = "User Cache"
    case userLogs = "User Logs"
    case brokenPrefs = "Broken Preferences"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .systemCache: return "desktopcomputer"
        case .userCache: return "person.crop.circle"
        case .userLogs: return "doc.text"
        case .brokenPrefs: return "gearshape.triangle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .systemCache: return "Temporary files from system components"
        case .userCache: return "Application caches and temporary data"
        case .userLogs: return "Log files from apps and services"
        case .brokenPrefs: return "Orphaned or corrupt preference files"
        }
    }
}

/// Represents a single junk file or folder that can be cleaned
struct JunkItem: Identifiable, Hashable {
    let id = UUID()
    let path: URL
    let size: Int64
    let category: JunkCategory
    var isSelected: Bool = true
    
    /// Human-readable file size
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    /// File or folder name
    var name: String {
        path.lastPathComponent
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: JunkItem, rhs: JunkItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Group of junk items by category
struct JunkGroup: Identifiable {
    let id = UUID()
    let category: JunkCategory
    var items: [JunkItem]
    
    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }
    
    var selectedSize: Int64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}
