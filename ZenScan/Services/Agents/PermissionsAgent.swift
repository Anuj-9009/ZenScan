import Foundation

/// Agent for auditing app permissions
actor PermissionsAgent {
    private let fileManager = FileManager.default
    
    /// Known permission types
    enum PermissionType: String, CaseIterable {
        case camera = "Camera"
        case microphone = "Microphone"
        case location = "Location"
        case contacts = "Contacts"
        case photos = "Photos"
        case fullDiskAccess = "Full Disk Access"
        case accessibility = "Accessibility"
        case screenRecording = "Screen Recording"
        case automation = "Automation"
    }
    
    /// Scan for apps with permissions
    func scanPermissions(progress: @escaping (Double, String) -> Void) async -> [PermissionCategory] {
        await MainActor.run { progress(0, "Scanning permissions...") }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var categories: [PermissionCategory] = []
                
                // Check TCC database for permissions
                let tccPath = self.fileManager.homeDirectoryForCurrentUser
                    .appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")
                
                // We can't directly read TCC.db (SIP protected), but we can check known apps
                // This is a simplified version that shows common permission-requiring apps
                
                DispatchQueue.main.async { progress(0.5, "Analyzing app permissions...") }
                
                // Camera apps
                categories.append(PermissionCategory(
                    type: .camera,
                    apps: self.getAppsWithPermission("camera")
                ))
                
                // Microphone apps
                categories.append(PermissionCategory(
                    type: .microphone,
                    apps: self.getAppsWithPermission("microphone")
                ))
                
                // Location apps
                categories.append(PermissionCategory(
                    type: .location,
                    apps: self.getAppsWithPermission("location")
                ))
                
                // Full Disk Access
                categories.append(PermissionCategory(
                    type: .fullDiskAccess,
                    apps: self.getFullDiskAccessApps()
                ))
                
                DispatchQueue.main.async { progress(1.0, "Scan complete") }
                continuation.resume(returning: categories.filter { !$0.apps.isEmpty })
            }
        }
    }
    
    /// Get apps that likely have a specific permission
    private func getAppsWithPermission(_ permission: String) -> [PermissionApp] {
        var apps: [PermissionApp] = []
        let applicationsPath = URL(fileURLWithPath: "/Applications")
        
        // Known apps by permission
        let knownApps: [String: [String]] = [
            "camera": ["Zoom.app", "Skype.app", "FaceTime.app", "Photo Booth.app", "Discord.app", "Slack.app"],
            "microphone": ["Zoom.app", "Skype.app", "FaceTime.app", "Discord.app", "Slack.app", "Voice Memos.app"],
            "location": ["Maps.app", "Weather.app", "Find My.app", "Photos.app"],
        ]
        
        if let appList = knownApps[permission] {
            for appName in appList {
                let appPath = applicationsPath.appendingPathComponent(appName)
                if fileManager.fileExists(atPath: appPath.path) {
                    apps.append(PermissionApp(
                        name: appName.replacingOccurrences(of: ".app", with: ""),
                        path: appPath,
                        bundleId: Bundle(url: appPath)?.bundleIdentifier ?? ""
                    ))
                }
            }
        }
        
        return apps
    }
    
    /// Get apps with Full Disk Access
    private func getFullDiskAccessApps() -> [PermissionApp] {
        var apps: [PermissionApp] = []
        let applicationsPath = URL(fileURLWithPath: "/Applications")
        
        // Apps that commonly request FDA
        let fdaApps = ["Terminal.app", "iTerm.app", "CleanMyMac X.app", "Carbon Copy Cloner.app", "Disk Utility.app"]
        
        for appName in fdaApps {
            let appPath = applicationsPath.appendingPathComponent(appName)
            if fileManager.fileExists(atPath: appPath.path) {
                apps.append(PermissionApp(
                    name: appName.replacingOccurrences(of: ".app", with: ""),
                    path: appPath,
                    bundleId: Bundle(url: appPath)?.bundleIdentifier ?? ""
                ))
            }
        }
        
        return apps
    }
    
    /// Open System Settings to specific permission
    func openPermissionSettings(for type: PermissionType) {
        let urlString: String
        switch type {
        case .camera:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
        case .microphone:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        case .location:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"
        case .contacts:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts"
        case .photos:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos"
        case .fullDiskAccess:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        case .accessibility:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        case .screenRecording:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        case .automation:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
        }
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

/// Permission category
struct PermissionCategory: Identifiable {
    let id = UUID()
    let type: PermissionsAgent.PermissionType
    let apps: [PermissionApp]
    
    var icon: String {
        switch type {
        case .camera: return "camera.fill"
        case .microphone: return "mic.fill"
        case .location: return "location.fill"
        case .contacts: return "person.crop.circle.fill"
        case .photos: return "photo.fill"
        case .fullDiskAccess: return "externaldrive.fill"
        case .accessibility: return "figure.walk"
        case .screenRecording: return "record.circle"
        case .automation: return "gearshape.2.fill"
        }
    }
}

/// App with permission
struct PermissionApp: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let bundleId: String
}

import AppKit
