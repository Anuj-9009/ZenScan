import Foundation
import AppKit

/// Represents an installed application with all its related files
struct InstalledApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let icon: NSImage?
    let appPath: URL
    var containerPaths: [URL] = []
    var totalSize: Int64 = 0
    var isSelected: Bool = false
    
    /// Human-readable total size
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    /// All paths related to this app (main bundle + containers)
    var allPaths: [URL] {
        [appPath] + containerPaths
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.id == rhs.id
    }
}

/// Application categories for filtering
enum AppCategory: String, CaseIterable {
    case all = "All Apps"
    case large = "Large Apps"
    case unused = "Unused"
    case system = "System Apps"
}
