import SwiftUI
import AppKit

@main
struct ZenScanApp: App {
    @StateObject private var dashboardVM = DashboardViewModel()
    @StateObject private var menuBarManager = MenuBarManager()
    
    @AppStorage("enableMenuBar") private var enableMenuBar = true
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dashboardVM)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    // Setup menu bar if enabled
                    if !enableMenuBar {
                        // Hide menu bar item
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            // Scan menu
            CommandMenu("Scan") {
                Button("Quick Scan") {
                    Task {
                        await dashboardVM.performSmartScan()
                    }
                }
                .keyboardShortcut("S", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Reset Scan") {
                    dashboardVM.resetScan()
                }
            }
            
            // Tools menu
            CommandMenu("Tools") {
                Button("Large Files Finder") {
                    // Navigate to Large Files
                }
                
                Button("Duplicate Finder") {
                    // Navigate to Duplicates
                }
                
                Button("Xcode Cleaner") {
                    // Navigate to Xcode Cleaner
                }
                
                Divider()
                
                Button("Empty Trash") {
                    emptyTrash()
                }
            }
        }
        
        // Settings window
        Settings {
            SettingsView()
                .frame(width: 500, height: 600)
        }
    }
    
    private func emptyTrash() {
        let url = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".Trash")
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for item in contents {
                try FileManager.default.removeItem(at: item)
            }
        } catch {
            print("Failed to empty trash: \(error)")
        }
    }
}
