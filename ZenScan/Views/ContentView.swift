import SwiftUI

/// Navigation item enum for sidebar (v2.1 with all modules)
enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Smart Scan"
    case systemJunk = "System Junk"
    case largeFiles = "Large Files"
    case duplicates = "Duplicates"
    case diskVisualizer = "Disk Visualizer"
    case downloads = "Downloads"
    case xcodeCleaner = "Xcode Cleaner"
    case uninstaller = "Uninstaller"
    case ramCleaner = "RAM Cleaner"
    case shredder = "File Shredder"
    case malware = "Malware Scanner"
    case battery = "Battery Health"
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
        case .xcodeCleaner: return "hammer.circle"
        case .uninstaller: return "square.stack.3d.up"
        case .ramCleaner: return "memorychip"
        case .shredder: return "scissors"
        case .malware: return "shield.lefthalf.filled"
        case .battery: return "battery.100"
        case .privacy: return "hand.raised.circle"
        case .optimization: return "bolt.circle"
        case .settings: return "gear"
        }
    }
    
    /// Group separators for visual hierarchy
    var showDividerAfter: Bool {
        switch self {
        case .dashboard, .xcodeCleaner, .battery, .optimization: return true
        default: return false
        }
    }
    
    /// Keyboard shortcut number (1-9, then 0)
    var shortcutNumber: String? {
        switch self {
        case .dashboard: return "1"
        case .systemJunk: return "2"
        case .largeFiles: return "3"
        case .duplicates: return "4"
        case .malware: return "5"
        case .uninstaller: return "6"
        case .privacy: return "7"
        case .optimization: return "8"
        case .settings: return "9"
        default: return nil
        }
    }
}

/// Main content view with sidebar navigation
struct ContentView: View {
    @EnvironmentObject var dashboardVM: DashboardViewModel
    @State private var selectedItem: NavigationItem = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showOnboarding = !OnboardingManager.hasCompletedOnboarding
    @State private var showConfetti = false
    @Environment(\.colorScheme) var colorScheme
    
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
                        
                        Text("v2.1")
                            .font(.caption2)
                            .foregroundColor(.slateGray)
                            .padding(.leading, 4)
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 16)
                    
                    Divider()
                        .background(Color.slateGray.opacity(0.3))
                    
                    // Navigation items
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(NavigationItem.allCases) { item in
                                NavigationButton(
                                    item: item,
                                    isSelected: selectedItem == item
                                ) {
                                    selectedItem = item
                                }
                                
                                if item.showDividerAfter {
                                    Divider()
                                        .background(Color.slateGray.opacity(0.2))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                }
                            }
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 8)
                    }
                    
                    Spacer()
                    
                    // Footer with version
                    Text("Version 2.1.0")
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
                
                detailView
                
                // Confetti overlay
                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
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
        .keyboardShortcut("5", modifiers: .command, action: { selectedItem = .malware })
        .keyboardShortcut("6", modifiers: .command, action: { selectedItem = .uninstaller })
        .keyboardShortcut("7", modifiers: .command, action: { selectedItem = .privacy })
        .keyboardShortcut("8", modifiers: .command, action: { selectedItem = .optimization })
        .keyboardShortcut("9", modifiers: .command, action: { selectedItem = .settings })
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
        case .privacy:
            PrivacyView()
        case .optimization:
            OptimizationView()
        case .settings:
            SettingsView()
        }
    }
    
    /// Trigger confetti animation
    func showSuccessAnimation() {
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showConfetti = false
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
                    .font(.system(size: 18))
                    .frame(width: 24)
                
                Text(item.rawValue)
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
                
                // Keyboard shortcut hint
                if let shortcut = item.shortcutNumber {
                    Text("⌘\(shortcut)")
                        .font(.caption2)
                        .foregroundColor(.slateGray.opacity(0.5))
                }
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

/// Confetti animation view
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
                animateParticles()
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<50).map { _ in
            ConfettiParticle(
                color: [.emeraldGreen, .frostWhite, .green, .cyan].randomElement()!,
                size: CGFloat.random(in: 4...12),
                position: CGPoint(
                    x: size.width / 2 + CGFloat.random(in: -50...50),
                    y: size.height / 2
                ),
                velocity: CGPoint(
                    x: CGFloat.random(in: -200...200),
                    y: CGFloat.random(in: -400...(-100))
                ),
                opacity: 1
            )
        }
    }
    
    private func animateParticles() {
        withAnimation(.easeOut(duration: 2)) {
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y + 300 // gravity
                particles[i].opacity = 0
            }
        }
    }
}

/// Confetti particle model
struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var velocity: CGPoint
    var opacity: Double
}

#Preview {
    ContentView()
        .environmentObject(DashboardViewModel())
        .frame(width: 1000, height: 700)
}
