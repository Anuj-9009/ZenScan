import SwiftUI

/// Disk space item for visualization
struct DiskSpaceItem: Identifiable {
    let id = UUID()
    let path: URL
    let name: String
    let size: Int64
    var children: [DiskSpaceItem]?
    var color: Color
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var isDirectory: Bool {
        children != nil
    }
    
    /// Generate color based on file type
    static func colorFor(path: URL) -> Color {
        let ext = path.pathExtension.lowercased()
        switch ext {
        case "app": return .blue
        case "dmg", "pkg", "zip", "rar": return .orange
        case "mp4", "mov", "avi", "mkv": return .purple
        case "mp3", "wav", "aac", "flac": return .pink
        case "jpg", "jpeg", "png", "gif", "heic": return .green
        case "pdf", "doc", "docx": return .red
        case "xcodeproj", "swift": return .cyan
        default: return .gray
        }
    }
}

/// Agent for disk space analysis
actor DiskSpaceAgent {
    private let fileManager = FileManager.default
    
    /// Analyze a directory and return space breakdown
    func analyzeDirectory(
        at url: URL,
        depth: Int = 2,
        progress: @escaping (String) -> Void
    ) async -> DiskSpaceItem? {
        progress("Analyzing \(url.lastPathComponent)...")
        return await scanDirectory(at: url, currentDepth: 0, maxDepth: depth)
    }
    
    private func scanDirectory(at url: URL, currentDepth: Int, maxDepth: Int) async -> DiskSpaceItem? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        
        var isDir: ObjCBool = false
        fileManager.fileExists(atPath: url.path, isDirectory: &isDir)
        
        if !isDir.boolValue {
            // It's a file
            let size = (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
            return DiskSpaceItem(
                path: url,
                name: url.lastPathComponent,
                size: size,
                children: nil,
                color: DiskSpaceItem.colorFor(path: url)
            )
        }
        
        // It's a directory
        guard let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) else {
            return nil
        }
        
        var totalSize: Int64 = 0
        var children: [DiskSpaceItem]? = nil
        
        if currentDepth < maxDepth {
            children = []
            for itemURL in contents {
                if let item = await scanDirectory(at: itemURL, currentDepth: currentDepth + 1, maxDepth: maxDepth) {
                    children?.append(item)
                    totalSize += item.size
                }
            }
            children?.sort { $0.size > $1.size }
            // Limit to top 20 items
            if let c = children, c.count > 20 {
                children = Array(c.prefix(20))
            }
        } else {
            // Calculate size without recursing
            totalSize = await calculateDirectorySize(at: url)
        }
        
        return DiskSpaceItem(
            path: url,
            name: url.lastPathComponent,
            size: totalSize,
            children: children,
            color: .emeraldGreen
        )
    }
    
    private func calculateDirectorySize(at url: URL) async -> Int64 {
        var size: Int64 = 0
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
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
