import Foundation
import AppKit

/// Agent for managing fonts
actor FontAgent {
    private let fileManager = FileManager.default
    
    /// Font directories
    private var fontPaths: [(name: String, path: URL)] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            ("User Fonts", home.appendingPathComponent("Library/Fonts")),
            ("System Fonts", URL(fileURLWithPath: "/Library/Fonts")),
        ]
    }
    
    /// Scan for installed fonts
    func scanFonts(progress: @escaping (Double, String) -> Void) async -> [FontItem] {
        await MainActor.run { progress(0, "Scanning fonts...") }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var fonts: [FontItem] = []
                let totalPaths = Double(self.fontPaths.count)
                
                for (index, fontPath) in self.fontPaths.enumerated() {
                    DispatchQueue.main.async {
                        progress(Double(index) / totalPaths, "Scanning \(fontPath.name)...")
                    }
                    
                    guard self.fileManager.isReadableFile(atPath: fontPath.path.path) else { continue }
                    
                    if let contents = try? self.fileManager.contentsOfDirectory(
                        at: fontPath.path,
                        includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]
                    ) {
                        for url in contents {
                            let ext = url.pathExtension.lowercased()
                            guard ["ttf", "otf", "ttc", "dfont", "woff", "woff2"].contains(ext) else { continue }
                            
                            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
                            
                            fonts.append(FontItem(
                                path: url,
                                name: url.deletingPathExtension().lastPathComponent,
                                size: Int64(values?.fileSize ?? 0),
                                isUserFont: fontPath.name == "User Fonts",
                                installDate: values?.creationDate
                            ))
                        }
                    }
                }
                
                DispatchQueue.main.async { progress(1.0, "Found \(fonts.count) fonts") }
                continuation.resume(returning: fonts.sorted { $0.name < $1.name })
            }
        }
    }
    
    /// Get font preview (first few characters)
    func getFontPreview(for font: FontItem) -> NSFont? {
        // Try to create font from file
        if let fontDescriptors = CTFontManagerCreateFontDescriptorsFromURL(font.path as CFURL) as? [CTFontDescriptor],
           let descriptor = fontDescriptors.first {
            let ctFont = CTFontCreateWithFontDescriptor(descriptor, 14, nil)
            return ctFont as NSFont
        }
        return nil
    }
    
    /// Delete user fonts
    func deleteFonts(_ fonts: [FontItem]) async -> (deleted: Int, failed: Int) {
        var deleted = 0
        var failed = 0
        
        for font in fonts where font.isUserFont {
            do {
                try fileManager.trashItem(at: font.path, resultingItemURL: nil)
                deleted += 1
            } catch {
                failed += 1
            }
        }
        
        return (deleted, failed)
    }
    
    /// Get total font count
    func totalFontSize(_ fonts: [FontItem]) -> Int64 {
        fonts.reduce(0) { $0 + $1.size }
    }
}

/// Font item model
struct FontItem: Identifiable {
    let id = UUID()
    let path: URL
    let name: String
    let size: Int64
    let isUserFont: Bool
    let installDate: Date?
    var isSelected: Bool = false
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var fontType: String {
        switch path.pathExtension.lowercased() {
        case "ttf": return "TrueType"
        case "otf": return "OpenType"
        case "ttc": return "TrueType Collection"
        case "dfont": return "Data Fork"
        case "woff", "woff2": return "Web Font"
        default: return "Font"
        }
    }
}
