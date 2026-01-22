import Foundation
import CryptoKit

/// Represents a group of duplicate files
struct DuplicateGroup: Identifiable {
    let id = UUID()
    let hash: String
    let size: Int64
    var files: [DuplicateFile]
    
    /// Total wasted space (all but one file)
    var wastedSpace: Int64 {
        size * Int64(max(0, files.count - 1))
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedWastedSpace: String {
        ByteCountFormatter.string(fromByteCount: wastedSpace, countStyle: .file)
    }
}

/// Represents a single file in a duplicate group
struct DuplicateFile: Identifiable, Hashable {
    let id = UUID()
    let path: URL
    let size: Int64
    let modificationDate: Date?
    var isSelected: Bool = false
    var isOriginal: Bool = false  // Suggested to keep
    
    var name: String {
        path.lastPathComponent
    }
    
    var parentPath: String {
        path.deletingLastPathComponent().path
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DuplicateFile, rhs: DuplicateFile) -> Bool {
        lhs.id == rhs.id
    }
}

/// Hash calculation helper using SHA256
struct FileHasher {
    /// Calculate SHA256 hash of file (first 64KB for speed + size check)
    static func quickHash(for url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer { try? handle.close() }
        
        // Read first 64KB for quick hash
        let data = handle.readData(ofLength: 65536)
        guard !data.isEmpty else { return nil }
        
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Calculate full file hash (for verification)
    static func fullHash(for url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
