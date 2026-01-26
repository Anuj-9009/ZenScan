import Foundation

/// Agent for Homebrew package manager cleanup
actor HomebrewAgent {
    private let fileManager = FileManager.default
    
    /// Homebrew paths
    private var brewPaths: [String: URL] {
        let homebrewPrefix: URL
        #if arch(arm64)
        homebrewPrefix = URL(fileURLWithPath: "/opt/homebrew")
        #else
        homebrewPrefix = URL(fileURLWithPath: "/usr/local")
        #endif
        
        return [
            "cache": homebrewPrefix.appendingPathComponent("Caches/Homebrew"),
            "logs": homebrewPrefix.appendingPathComponent("var/log"),
            "cellar": homebrewPrefix.appendingPathComponent("Cellar")
        ]
    }
    
    /// Alternative cache location
    private var userCachePath: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/Homebrew")
    }
    
    /// Check if Homebrew is installed
    var isInstalled: Bool {
        let brewPath = "/opt/homebrew/bin/brew"
        let altPath = "/usr/local/bin/brew"
        return fileManager.fileExists(atPath: brewPath) || fileManager.fileExists(atPath: altPath)
    }
    
    /// Scan for Homebrew caches and cleanup opportunities
    func scan(progress: @escaping (Double, String) -> Void) async -> HomebrewScanResult {
        await MainActor.run { progress(0, "Checking Homebrew installation...") }
        
        guard isInstalled else {
            return HomebrewScanResult(isInstalled: false, cacheSize: 0, cacheItems: [], outdatedPackages: [])
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result = HomebrewScanResult(isInstalled: true, cacheSize: 0, cacheItems: [], outdatedPackages: [])
                
                // Scan cache
                DispatchQueue.main.async { progress(0.2, "Scanning Homebrew cache...") }
                
                let cachePaths = [self.userCachePath, self.brewPaths["cache"]].compactMap { $0 }
                
                for cachePath in cachePaths {
                    if self.fileManager.fileExists(atPath: cachePath.path) {
                        if let contents = try? self.fileManager.contentsOfDirectory(at: cachePath, includingPropertiesForKeys: [.fileSizeKey]) {
                            for item in contents {
                                if let values = try? item.resourceValues(forKeys: [.fileSizeKey, .totalFileSizeKey]) {
                                    let size = Int64(values.totalFileSize ?? values.fileSize ?? 0)
                                    result.cacheItems.append(HomebrewCacheItem(
                                        path: item,
                                        name: item.lastPathComponent,
                                        size: size
                                    ))
                                    result.cacheSize += size
                                }
                            }
                        }
                    }
                }
                
                // Get outdated packages (run brew outdated)
                DispatchQueue.main.async { progress(0.6, "Checking outdated packages...") }
                
                result.outdatedPackages = self.getOutdatedPackages()
                
                DispatchQueue.main.async { progress(1.0, "Scan complete") }
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Get outdated packages using brew command
    private func getOutdatedPackages() -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
        process.arguments = ["outdated", "--quiet"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
            }
        } catch {
            // Brew not available or failed
        }
        
        return []
    }
    
    /// Clean Homebrew cache
    func cleanCache() async -> (deleted: Int, failed: Int, freedBytes: Int64) {
        var deleted = 0
        var failed = 0
        var freedBytes: Int64 = 0
        
        let cachePaths = [userCachePath, brewPaths["cache"]].compactMap { $0 }
        
        for cachePath in cachePaths {
            if let contents = try? fileManager.contentsOfDirectory(at: cachePath, includingPropertiesForKeys: [.fileSizeKey]) {
                for item in contents {
                    do {
                        let size = (try? item.resourceValues(forKeys: [.totalFileSizeKey]).totalFileSize) ?? 0
                        try fileManager.trashItem(at: item, resultingItemURL: nil)
                        deleted += 1
                        freedBytes += Int64(size)
                    } catch {
                        failed += 1
                    }
                }
            }
        }
        
        return (deleted, failed, freedBytes)
    }
    
    /// Run brew cleanup
    func runBrewCleanup() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
                process.arguments = ["cleanup", "--prune=all"]
                process.standardOutput = FileHandle.nullDevice
                process.standardError = FileHandle.nullDevice
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    continuation.resume(returning: process.terminationStatus == 0)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }
}

/// Homebrew scan result
struct HomebrewScanResult {
    var isInstalled: Bool
    var cacheSize: Int64
    var cacheItems: [HomebrewCacheItem]
    var outdatedPackages: [String]
    
    var formattedCacheSize: String {
        ByteCountFormatter.string(fromByteCount: cacheSize, countStyle: .file)
    }
}

/// Cache item
struct HomebrewCacheItem: Identifiable {
    let id = UUID()
    let path: URL
    let name: String
    let size: Int64
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
