import SwiftUI

/// Navigation item enum for sidebar (v3.0 with all modules)
enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Smart Scan"
    case systemJunk = "System Junk"
    case largeFiles = "Large Files"
    case duplicates = "Duplicates"
    case diskVisualizer = "Disk Visualizer"
    case downloads = "Downloads"
    case developerTools = "Developer Tools"
    case xcodeCleaner = "Xcode Cleaner"
    case uninstaller = "Uninstaller"
    case ramCleaner = "RAM Cleaner"
    case shredder = "File Shredder"
    case malware = "Malware Scanner"
    case battery = "Battery Health"
    case permissions = "Permissions"
    case privacy = "Privacy"
    case optimization = "Optimization"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.33percent"
        case .systemJunk: return "trash.slash.circle"
        case .largeFiles: return "doc.badge.gearshape"
        case .duplicates: return "doc.on.doc"
        case .diskVisualizer: return "square.grid.3x3.fill"
        case .downloads: return "arrow.down.circle"
        case .developerTools: return "hammer.fill"
        case .xcodeCleaner: return "hammer.circle"
        case .uninstaller: return "square.stack.3d.up"
        case .ramCleaner: return "memorychip"
        case .shredder: return "scissors"
        case .malware: return "shield.lefthalf.filled"
        case .battery: return "battery.100"
        case .permissions: return "hand.raised.circle"
        case .privacy: return "eye.slash.circle"
        case .optimization: return "bolt.circle"
        case .settings: return "gear"
        }
    }
    
    /// Section groupings
    var section: NavigationSection {
        switch self {
        case .dashboard: return .main
        case .systemJunk, .largeFiles, .duplicates, .diskVisualizer, .downloads: return .cleanup
        case .developerTools, .xcodeCleaner: return .developer
        case .uninstaller, .ramCleaner, .shredder: return .tools
        case .malware, .battery, .permissions, .privacy: return .security
        case .optimization, .settings: return .system
        }
    }
    
    /// Keyboard shortcut number
    var shortcutNumber: String? {
        switch self {
        case .dashboard: return "1"
        case .systemJunk: return "2"
        case .largeFiles: return "3"
        case .duplicates: return "4"
        case .developerTools: return "5"
        case .uninstaller: return "6"
        case .privacy: return "7"
        case .optimization: return "8"
        case .settings: return "9"
        default: return nil
        }
    }
}

/// Navigation sections
enum NavigationSection: String, CaseIterable {
    case main = "Main"
    case cleanup = "Cleanup"
    case developer = "Development"
    case tools = "Tools"
    case security = "Security"
    case system = "System"
    
    var items: [NavigationItem] {
        NavigationItem.allCases.filter { $0.section == self }
    }
}

/// Main content view with improved sidebar navigation
struct ContentView: View {
    @EnvironmentObject var dashboardVM: DashboardViewModel
    @State private var selectedItem: NavigationItem = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showOnboarding = !OnboardingManager.hasCompletedOnboarding
    @State private var collapsedSections: Set<NavigationSection> = []
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            ZStack {
                Color.deepSpaceBlue
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // App header
                    appHeader
                    
                    Divider()
                        .background(Color.slateGray.opacity(0.3))
                    
                    // Navigation sections
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(NavigationSection.allCases, id: \.self) { section in
                                sectionView(section)
                            }
                        }
                        .padding(.top, 12)
                        .padding(.horizontal, 8)
                    }
                    
                    Spacer()
                    
                    // Footer
                    Text("ZenScan v3.0")
                        .font(.caption)
                        .foregroundColor(.slateGray)
                        .padding(.bottom, 16)
                }
            }
            .frame(minWidth: 220)
        } detail: {
            // Content area
            ZStack {
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                detailView
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        // Keyboard shortcuts
        .keyboardShortcut("1", modifiers: .command, action: { selectedItem = .dashboard })
        .keyboardShortcut("2", modifiers: .command, action: { selectedItem = .systemJunk })
        .keyboardShortcut("3", modifiers: .command, action: { selectedItem = .largeFiles })
        .keyboardShortcut("4", modifiers: .command, action: { selectedItem = .duplicates })
        .keyboardShortcut("5", modifiers: .command, action: { selectedItem = .developerTools })
        .keyboardShortcut("6", modifiers: .command, action: { selectedItem = .uninstaller })
        .keyboardShortcut("7", modifiers: .command, action: { selectedItem = .privacy })
        .keyboardShortcut("8", modifiers: .command, action: { selectedItem = .optimization })
        .keyboardShortcut("9", modifiers: .command, action: { selectedItem = .settings })
    }
    
    private var appHeader: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.emeraldGreen)
            
            Text("ZenScan")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.frostWhite)
            
            Text("v3.0")
                .font(.caption2)
                .foregroundColor(.slateGray)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.emeraldGreen.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
    }
    
    private func sectionView(_ section: NavigationSection) -> some View {
        VStack(spacing: 4) {
            // Section header
            if section != .main {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if collapsedSections.contains(section) {
                            collapsedSections.remove(section)
                        } else {
                            collapsedSections.insert(section)
                        }
                    }
                } label: {
                    HStack {
                        Text(section.rawValue.uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.slateGray.opacity(0.7))
                        
                        Spacer()
                        
                        Image(systemName: collapsedSections.contains(section) ? "chevron.right" : "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.slateGray.opacity(0.5))
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
                .buttonStyle(.plain)
            }
            
            // Section items
            if !collapsedSections.contains(section) {
                ForEach(section.items) { item in
                    NavigationButton(
                        item: item,
                        isSelected: selectedItem == item
                    ) {
                        selectedItem = item
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .dashboard:
            DashboardView()
        case .systemJunk:
            SystemJunkView()
        case .largeFiles:
            LargeFilesView()
        case .duplicates:
            DuplicateView()
        case .diskVisualizer:
            DiskVisualizerView()
        case .downloads:
            DownloadManagerView()
        case .developerTools:
            DeveloperToolsView()
        case .xcodeCleaner:
            XcodeCleanerView()
        case .uninstaller:
            UninstallerView()
        case .ramCleaner:
            RAMCleanerView()
        case .shredder:
            ShredderView()
        case .malware:
            MalwareScannerView()
        case .battery:
            BatteryHealthView()
        case .permissions:
            PermissionsView()
        case .privacy:
            PrivacyView()
        case .optimization:
            OptimizationView()
        case .settings:
            SettingsView()
        }
    }
}

/// Keyboard shortcut extension
extension View {
    func keyboardShortcut(_ key: String, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        self.background(
            Button(action: action) { EmptyView() }
                .keyboardShortcut(KeyEquivalent(Character(key)), modifiers: modifiers)
                .frame(width: 0, height: 0)
                .opacity(0)
        )
    }
}

/// Sidebar navigation button
struct NavigationButton: View {
    let item: NavigationItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 16))
                    .frame(width: 22)
                
                Text(item.rawValue)
                    .font(.system(size: 13, weight: .medium))
                
                Spacer()
                
                // Keyboard shortcut hint
                if let shortcut = item.shortcutNumber {
                    Text("⌘\(shortcut)")
                        .font(.system(size: 10))
                        .foregroundColor(.slateGray.opacity(0.5))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .frostWhite : .slateGray)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.emeraldGreen.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.emeraldGreen.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environmentObject(DashboardViewModel())
        .frame(width: 1000, height: 700)
}
