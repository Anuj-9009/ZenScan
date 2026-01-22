import SwiftUI

/// Settings view for app configuration
struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("enableMenuBar") private var enableMenuBar = true
    @AppStorage("scheduledCleaningEnabled") private var scheduledCleaningEnabled = false
    @AppStorage("scheduledCleaningInterval") private var scheduledCleaningInterval = 7 // days
    @AppStorage("moveToTrash") private var moveToTrash = true
    @AppStorage("showConfirmations") private var showConfirmations = true
    
    @State private var showResetAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.title.weight(.bold))
                            .foregroundColor(.frostWhite)
                        
                        Text("Configure ZenScan preferences")
                            .font(.subheadline)
                            .foregroundColor(.slateGray)
                    }
                    Spacer()
                }
                .padding(.bottom, 8)
                
                // Appearance
                SettingsSection(title: "Appearance", icon: "paintbrush") {
                    SettingsToggle(
                        title: "Dark Mode",
                        subtitle: "Use dark color scheme",
                        isOn: $isDarkMode
                    )
                }
                
                // Menu Bar
                SettingsSection(title: "Menu Bar", icon: "menubar.rectangle") {
                    SettingsToggle(
                        title: "Show in Menu Bar",
                        subtitle: "Quick access from menu bar",
                        isOn: $enableMenuBar
                    )
                }
                
                // Scheduled Cleaning
                SettingsSection(title: "Scheduled Cleaning", icon: "calendar.badge.clock") {
                    SettingsToggle(
                        title: "Enable Scheduled Cleaning",
                        subtitle: "Automatically clean junk files",
                        isOn: $scheduledCleaningEnabled
                    )
                    
                    if scheduledCleaningEnabled {
                        HStack {
                            Text("Clean every")
                                .foregroundColor(.frostWhite)
                            
                            Picker("", selection: $scheduledCleaningInterval) {
                                Text("Daily").tag(1)
                                Text("Weekly").tag(7)
                                Text("Monthly").tag(30)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        .padding(.top, 8)
                    }
                }
                
                // Safety
                SettingsSection(title: "Safety", icon: "shield") {
                    SettingsToggle(
                        title: "Move to Trash",
                        subtitle: "Move files to Trash instead of permanent deletion",
                        isOn: $moveToTrash
                    )
                    
                    SettingsToggle(
                        title: "Show Confirmations",
                        subtitle: "Ask before deleting files",
                        isOn: $showConfirmations
                    )
                }
                
                // Permissions
                SettingsSection(title: "Permissions", icon: "lock.shield") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Full Disk Access")
                                .font(.headline)
                                .foregroundColor(.frostWhite)
                            
                            Text("Required for scanning protected folders")
                                .font(.caption)
                                .foregroundColor(.slateGray)
                        }
                        
                        Spacer()
                        
                        Button("Open Settings") {
                            openPrivacySettings()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.emeraldGreen)
                    }
                }
                
                // Reset
                SettingsSection(title: "Reset", icon: "arrow.counterclockwise") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reset All Settings")
                                .font(.headline)
                                .foregroundColor(.frostWhite)
                            
                            Text("Restore default settings")
                                .font(.caption)
                                .foregroundColor(.slateGray)
                        }
                        
                        Spacer()
                        
                        Button("Reset") {
                            showResetAlert = true
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                    }
                }
                
                // About
                SettingsSection(title: "About", icon: "info.circle") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ZenScan v2.0")
                                .font(.headline)
                                .foregroundColor(.frostWhite)
                            
                            Text("macOS System Maintenance Utility")
                                .font(.caption)
                                .foregroundColor(.slateGray)
                        }
                        
                        Spacer()
                        
                        Link("GitHub", destination: URL(string: "https://github.com/Anuj-9009/ZenScan")!)
                            .foregroundColor(.emeraldGreen)
                    }
                }
            }
            .padding(24)
        }
        .alert("Reset Settings?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetSettings()
            }
        } message: {
            Text("This will restore all settings to their defaults.")
        }
    }
    
    private func openPrivacySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
    
    private func resetSettings() {
        isDarkMode = true
        enableMenuBar = true
        scheduledCleaningEnabled = false
        scheduledCleaningInterval = 7
        moveToTrash = true
        showConfirmations = true
    }
}

/// Settings section container
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.emeraldGreen)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                }
                
                content
            }
        }
    }
}

/// Settings toggle row
struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.frostWhite)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(.emeraldGreen)
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 700, height: 600)
        .background(Color.backgroundGradient)
}
