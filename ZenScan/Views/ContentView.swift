import SwiftUI

/// Navigation item enum for sidebar
enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Smart Scan"
    case systemJunk = "System Junk"
    case uninstaller = "Uninstaller"
    case privacy = "Privacy"
    case optimization = "Optimization"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.33percent"
        case .systemJunk: return "trash.slash.circle"
        case .uninstaller: return "square.stack.3d.up"
        case .privacy: return "hand.raised.circle"
        case .optimization: return "bolt.circle"
        }
    }
}

/// Main content view with sidebar navigation
struct ContentView: View {
    @EnvironmentObject var dashboardVM: DashboardViewModel
    @State private var selectedItem: NavigationItem = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            ZStack {
                Color.deepSpaceBlue
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // App header
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.emeraldGreen)
                        
                        Text("ZenScan")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.frostWhite)
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 16)
                    
                    Divider()
                        .background(Color.slateGray.opacity(0.3))
                    
                    // Navigation items
                    VStack(spacing: 4) {
                        ForEach(NavigationItem.allCases) { item in
                            NavigationButton(
                                item: item,
                                isSelected: selectedItem == item
                            ) {
                                selectedItem = item
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 8)
                    
                    Spacer()
                    
                    // Footer with version
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.slateGray)
                        .padding(.bottom, 16)
                }
            }
            .frame(minWidth: 200)
        } detail: {
            // Content area
            ZStack {
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                switch selectedItem {
                case .dashboard:
                    DashboardView()
                case .systemJunk:
                    SystemJunkView()
                case .uninstaller:
                    UninstallerView()
                case .privacy:
                    PrivacyView()
                case .optimization:
                    OptimizationView()
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
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
                    .font(.system(size: 18))
                    .frame(width: 24)
                
                Text(item.rawValue)
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
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
        .frame(width: 900, height: 600)
}
