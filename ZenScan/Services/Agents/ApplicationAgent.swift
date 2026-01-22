import Foundation
import AppKit

/// Agent responsible for scanning installed applications
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
    
    /// Scan for all installed applications
    func scanApplications(progress: @escaping (Double, String) -> Void) async -> [InstalledApp] {
        var apps: [InstalledApp] = []
        var processed = 0
        
        progress(0, "Finding applications...")
        
        // Collect all app bundles
        var appBundles: [URL] = []
        for basePath in applicationPaths {
            guard let contents = try? fileManager.contentsOfDirectory(at: basePath, includingPropertiesForKeys: nil) else {
                continue
            }
            appBundles.append(contentsOf: contents.filter { $0.pathExtension == "app" })
        }
        
        let totalApps = Double(appBundles.count)
        
        for appURL in appBundles {
            processed += 1
            let appName = appURL.deletingPathExtension().lastPathComponent
            progress(Double(processed) / totalApps, "Scanning \(appName)...")
            
            if let app = await scanApplication(at: appURL) {
                apps.append(app)
            }
        }
        
        progress(1.0, "Scan complete")
        return apps.sorted { $0.totalSize > $1.totalSize }
    }
    
    /// Scan a single application
    private func scanApplication(at url: URL) async -> InstalledApp? {
        let bundle = Bundle(url: url)
        guard let bundleIdentifier = bundle?.bundleIdentifier else {
            return nil
        }
        
        let appName = bundle?.infoDictionary?["CFBundleName"] as? String 
            ?? url.deletingPathExtension().lastPathComponent
        
        // Get app icon
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        
        // Calculate app bundle size
        var totalSize = try? await fileSystemAgent.fileSize(at: url)
        totalSize = totalSize ?? 0
        
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
                    if let containerSize = try? await fileSystemAgent.fileSize(at: path) {
                        totalSize = (totalSize ?? 0) + containerSize
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
            totalSize: totalSize ?? 0
        )
    }
    
    /// Uninstall an application and its related files
    func uninstallApplication(_ app: InstalledApp) async throws -> (deleted: Int, failed: Int) {
        return try await fileSystemAgent.deleteItems(at: app.allPaths)
    }
}
