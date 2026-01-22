import Foundation

/// Agent responsible for cleaning Xcode caches and build artifacts
actor XcodeAgent {
    private let fileSystemAgent = FileSystemAgent()
    private let fileManager = FileManager.default
    
    /// Xcode cache locations
    struct XcodeLocation {
        let name: String
        let icon: String
        let path: URL
        let description: String
    }
    
    /// Get all Xcode cache locations
    func getCacheLocations() -> [XcodeLocation] {
        let home = fileManager.homeDirectoryForCurrentUser
        let library = home.appendingPathComponent("Library")
        
        return [
            XcodeLocation(
                name: "DerivedData",
                icon: "hammer.fill",
                path: library.appendingPathComponent("Developer/Xcode/DerivedData"),
                description: "Build intermediates and indexes"
            ),
            XcodeLocation(
                name: "Archives",
                icon: "archivebox.fill",
                path: library.appendingPathComponent("Developer/Xcode/Archives"),
                description: "App archives for distribution"
            ),
            XcodeLocation(
                name: "iOS DeviceSupport",
                icon: "iphone",
                path: library.appendingPathComponent("Developer/Xcode/iOS DeviceSupport"),
                description: "Debug symbols for iOS devices"
            ),
            XcodeLocation(
                name: "watchOS DeviceSupport",
                icon: "applewatch",
                path: library.appendingPathComponent("Developer/Xcode/watchOS DeviceSupport"),
                description: "Debug symbols for Apple Watch"
            ),
            XcodeLocation(
                name: "CoreSimulator Devices",
                icon: "ipad.and.iphone",
                path: library.appendingPathComponent("Developer/CoreSimulator/Devices"),
                description: "iOS Simulator data"
            ),
            XcodeLocation(
                name: "CoreSimulator Caches",
                icon: "memorychip",
                path: library.appendingPathComponent("Developer/CoreSimulator/Caches"),
                description: "Simulator runtime caches"
            ),
            XcodeLocation(
                name: "Xcode Caches",
                icon: "internaldrive",
                path: library.appendingPathComponent("Caches/com.apple.dt.Xcode"),
                description: "Xcode application cache"
            ),
            XcodeLocation(
                name: "Swift Package Cache",
                icon: "shippingbox.fill",
                path: library.appendingPathComponent("Caches/org.swift.swiftpm"),
                description: "Swift Package Manager cache"
            ),
            XcodeLocation(
                name: "Module Cache",
                icon: "square.stack.3d.up.fill",
                path: library.appendingPathComponent("Developer/Xcode/DerivedData/ModuleCache.noindex"),
                description: "Precompiled module cache"
            ),
        ]
    }
    
    /// Scan Xcode caches and return sizes
    func scanXcodeCaches(progress: @escaping (Double, String) -> Void) async -> [XcodeCacheItem] {
        let locations = getCacheLocations()
        var items: [XcodeCacheItem] = []
        let total = Double(locations.count)
        
        for (index, location) in locations.enumerated() {
            progress(Double(index) / total, "Scanning \(location.name)...")
            
            if fileManager.fileExists(atPath: location.path.path) {
                if let size = try? await fileSystemAgent.fileSize(at: location.path) {
                    items.append(XcodeCacheItem(
                        name: location.name,
                        icon: location.icon,
                        path: location.path,
                        description: location.description,
                        size: size
                    ))
                }
            }
        }
        
        progress(1.0, "Scan complete")
        return items.filter { $0.size > 0 }.sorted { $0.size > $1.size }
    }
    
    /// Delete selected cache items
    func deleteItems(_ items: [XcodeCacheItem]) async -> (deleted: Int, failed: Int, freedSpace: Int64) {
        var deleted = 0
        var failed = 0
        var freedSpace: Int64 = 0
        
        for item in items {
            do {
                freedSpace += item.size
                try fileManager.removeItem(at: item.path)
                deleted += 1
            } catch {
                failed += 1
                freedSpace -= item.size
            }
        }
        
        return (deleted, failed, freedSpace)
    }
}

/// Represents an Xcode cache item
struct XcodeCacheItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let path: URL
    let description: String
    let size: Int64
    var isSelected: Bool = false
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: XcodeCacheItem, rhs: XcodeCacheItem) -> Bool {
        lhs.id == rhs.id
    }
}
