import Foundation
import AppKit
import ServiceManagement

/// Agent responsible for managing processes and login items
actor ProcessAgent {
    private let fileManager = FileManager.default
    
    /// Get all login items and background processes
    func scanProcesses(progress: @escaping (Double, String) -> Void) async -> [ProcessCategory: [ProcessItem]] {
        var results: [ProcessCategory: [ProcessItem]] = [:]
        
        progress(0.2, "Scanning login items...")
        results[.loginItems] = await getLoginItems()
        
        progress(0.5, "Scanning background processes...")
        results[.backgroundProcesses] = getBackgroundProcesses()
        
        progress(0.7, "Scanning launch agents...")
        results[.launchAgents] = await getLaunchAgents()
        
        progress(1.0, "Scan complete")
        return results
    }
    
    /// Get login items using SMAppService (macOS 13+)
    private func getLoginItems() async -> [ProcessItem] {
        var items: [ProcessItem] = []
        
        // Scan LaunchAgents for login items
        let launchAgentsPath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        
        guard let contents = try? fileManager.contentsOfDirectory(at: launchAgentsPath, includingPropertiesForKeys: nil) else {
            return items
        }
        
        for plistURL in contents.filter({ $0.pathExtension == "plist" }) {
            if let plist = NSDictionary(contentsOf: plistURL),
               let runAtLoad = plist["RunAtLoad"] as? Bool, runAtLoad {
                let label = plist["Label"] as? String ?? plistURL.deletingPathExtension().lastPathComponent
                items.append(ProcessItem(
                    name: label,
                    bundleIdentifier: label,
                    path: plistURL,
                    isLoginItem: true
                ))
            }
        }
        
        return items
    }
    
    /// Get currently running background processes
    private func getBackgroundProcesses() -> [ProcessItem] {
        let runningApps = NSWorkspace.shared.runningApplications
        
        return runningApps
            .filter { $0.activationPolicy == .accessory || $0.activationPolicy == .prohibited }
            .compactMap { app -> ProcessItem? in
                guard let name = app.localizedName else { return nil }
                return ProcessItem(
                    name: name,
                    bundleIdentifier: app.bundleIdentifier,
                    path: app.bundleURL,
                    isLoginItem: false
                )
            }
    }
    
    /// Get user launch agents
    private func getLaunchAgents() async -> [ProcessItem] {
        var items: [ProcessItem] = []
        let launchAgentsPath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        
        guard let contents = try? fileManager.contentsOfDirectory(at: launchAgentsPath, includingPropertiesForKeys: nil) else {
            return items
        }
        
        for plistURL in contents.filter({ $0.pathExtension == "plist" }) {
            if let plist = NSDictionary(contentsOf: plistURL) {
                let label = plist["Label"] as? String ?? plistURL.deletingPathExtension().lastPathComponent
                let program = plist["Program"] as? String
                
                items.append(ProcessItem(
                    name: label,
                    bundleIdentifier: label,
                    path: program.map { URL(fileURLWithPath: $0) },
                    isLoginItem: plist["RunAtLoad"] as? Bool ?? false
                ))
            }
        }
        
        return items
    }
    
    /// Disable a login item
    func disableLoginItem(_ item: ProcessItem) async throws {
        guard let path = item.path else { return }
        
        // Move the plist to a disabled folder
        let disabledPath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/Disabled")
        
        try fileManager.createDirectory(at: disabledPath, withIntermediateDirectories: true)
        
        let destinationPath = disabledPath.appendingPathComponent(path.lastPathComponent)
        try fileManager.moveItem(at: path, to: destinationPath)
    }
    
    /// Terminate a background process
    func terminateProcess(_ item: ProcessItem) async throws {
        guard let bundleId = item.bundleIdentifier else { return }
        
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps where app.bundleIdentifier == bundleId {
            app.terminate()
        }
    }
}
