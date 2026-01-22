import Foundation
import AppKit

/// Agent responsible for scanning installed applications with improved performance
actor ApplicationAgent {
    private let fileSystemAgent = FileSystemAgent()
    private let fileManager = FileManager.default
    
    /// Scan paths for applications
    private let applicationPaths: [URL] = [
        URL(fileURLWithPath: "/Applications"),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
    ]
    
    /// Container paths for app data
    private var containerBasePaths: [URL] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent("Library/Application Support"),
            home.appendingPathComponent("Library/Containers"),
            home.appendingPathComponent("Library/Caches"),
            home.appendingPathComponent("Library/Preferences"),
            home.appendingPathComponent("Library/Saved Application State")
        ]
    }
    
    /// Scan for all installed applications with improved async handling
    func scanApplications(progress: @escaping (Double, String) -> Void) async -> [InstalledApp] {
        // Report progress on main thread
        await MainActor.run {
            progress(0, "Finding applications...")
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var apps: [InstalledApp] = []
                var processed = 0
                
                // Collect all app bundles
                var appBundles: [URL] = []
                for basePath in self.applicationPaths {
                    guard let contents = try? self.fileManager.contentsOfDirectory(
                        at: basePath,
                        includingPropertiesForKeys: [.isApplicationKey]
                    ) else { continue }
                    appBundles.append(contentsOf: contents.filter { $0.pathExtension == "app" })
                }
                
                let totalApps = Double(max(appBundles.count, 1))
                
                for appURL in appBundles {
                    autoreleasepool {
                        processed += 1
                        let appName = appURL.deletingPathExtension().lastPathComponent
                        
                        // Update progress on main thread
                        DispatchQueue.main.async {
                            progress(Double(processed) / totalApps, "Scanning \(appName)...")
                        }
                        
                        if let app = self.scanApplicationSync(at: appURL) {
                            apps.append(app)
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    progress(1.0, "Scan complete")
                }
                
                continuation.resume(returning: apps.sorted { $0.totalSize > $1.totalSize })
            }
        }
    }
    
    /// Scan a single application synchronously
    private func scanApplicationSync(at url: URL) -> InstalledApp? {
        let bundle = Bundle(url: url)
        guard let bundleIdentifier = bundle?.bundleIdentifier else {
            return nil
        }
        
        let appName = bundle?.infoDictionary?["CFBundleName"] as? String 
            ?? url.deletingPathExtension().lastPathComponent
        
        // Get app icon (must be on main thread for NSWorkspace)
        var icon: NSImage?
        DispatchQueue.main.sync {
            icon = NSWorkspace.shared.icon(forFile: url.path)
        }
        
        // Calculate app bundle size (quick estimate)
        var totalSize: Int64 = 0
        if let values = try? url.resourceValues(forKeys: [.totalFileSizeKey, .fileSizeKey]) {
            totalSize = Int64(values.totalFileSize ?? values.fileSize ?? 0)
        }
        
        // Find related container paths
        var containerPaths: [URL] = []
        for basePath in containerBasePaths {
            let potentialPaths = [
                basePath.appendingPathComponent(bundleIdentifier),
                basePath.appendingPathComponent(appName)
            ]
            
            for path in potentialPaths {
                if fileManager.fileExists(atPath: path.path) {
                    containerPaths.append(path)
                    // Quick size estimate for containers
                    if let values = try? path.resourceValues(forKeys: [.totalFileSizeKey]) {
                        totalSize += Int64(values.totalFileSize ?? 0)
                    }
                }
            }
        }
        
        return InstalledApp(
            name: appName,
            bundleIdentifier: bundleIdentifier,
            icon: icon,
            appPath: url,
            containerPaths: containerPaths,
            totalSize: totalSize
        )
    }
    
    /// Uninstall an application and its related files
    func uninstallApplication(_ app: InstalledApp) async throws -> (deleted: Int, failed: Int) {
        let result = try await fileSystemAgent.deleteItems(at: app.allPaths)
        return (result.deleted, result.failed)
    }
}
