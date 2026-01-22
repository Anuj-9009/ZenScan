import Foundation
import CryptoKit

/// Agent for secure file shredding
actor ShredderAgent {
    private let fileManager = FileManager.default
    
    /// Shred a file with multiple overwrite passes
    func shredFile(at url: URL, passes: Int = 3, progress: @escaping (Double, String) -> Void) async throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw ShredderError.fileNotFound
        }
        
        // Get file size
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            throw ShredderError.cannotGetSize
        }
        
        // Open file for writing
        guard let handle = FileHandle(forWritingAtPath: url.path) else {
            throw ShredderError.cannotOpenFile
        }
        
        defer { try? handle.close() }
        
        let chunkSize = 1024 * 1024 // 1MB chunks
        let totalChunks = Int(fileSize / Int64(chunkSize)) + 1
        
        for pass in 0..<passes {
            progress(Double(pass) / Double(passes), "Pass \(pass + 1) of \(passes)")
            
            try handle.seek(toOffset: 0)
            
            for chunk in 0..<totalChunks {
                let bytesToWrite = min(chunkSize, Int(fileSize) - (chunk * chunkSize))
                if bytesToWrite <= 0 { break }
                
                // Generate pattern based on pass type
                let pattern = getPattern(for: pass, size: bytesToWrite)
                try handle.write(contentsOf: pattern)
                
                let chunkProgress = Double(chunk) / Double(totalChunks)
                let totalProgress = (Double(pass) + chunkProgress) / Double(passes)
                progress(totalProgress, "Pass \(pass + 1): \(Int(chunkProgress * 100))%")
            }
            
            try handle.synchronize()
        }
        
        // Final deletion
        progress(1.0, "Removing file...")
        try fileManager.removeItem(at: url)
    }
    
    /// Generate overwrite pattern for a pass
    private func getPattern(for pass: Int, size: Int) -> Data {
        switch pass % 3 {
        case 0:
            // All zeros
            return Data(repeating: 0x00, count: size)
        case 1:
            // All ones
            return Data(repeating: 0xFF, count: size)
        default:
            // Random data
            var bytes = [UInt8](repeating: 0, count: size)
            for i in 0..<size {
                bytes[i] = UInt8.random(in: 0...255)
            }
            return Data(bytes)
        }
    }
    
    /// Shred multiple files
    func shredFiles(_ urls: [URL], passes: Int = 3, progress: @escaping (Double, String) -> Void) async throws {
        for (index, url) in urls.enumerated() {
            let fileProgress = Double(index) / Double(urls.count)
            progress(fileProgress, "Shredding \(url.lastPathComponent)...")
            
            try await shredFile(at: url, passes: passes) { subProgress, status in
                let totalProgress = fileProgress + (subProgress / Double(urls.count))
                progress(totalProgress, status)
            }
        }
        progress(1.0, "Complete")
    }
}

enum ShredderError: Error, LocalizedError {
    case fileNotFound
    case cannotGetSize
    case cannotOpenFile
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "File not found"
        case .cannotGetSize: return "Cannot determine file size"
        case .cannotOpenFile: return "Cannot open file for writing"
        }
    }
}
