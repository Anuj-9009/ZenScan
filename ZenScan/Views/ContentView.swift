import SwiftUI

/// Navigation item enum for sidebar (v2.0 with new modules)
enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Smart Scan"
    case systemJunk = "System Junk"
    case largeFiles = "Large Files"
    case duplicates = "Duplicates"
    case xcodeCleaner = "Xcode Cleaner"
    case uninstaller = "Uninstaller"
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
        case .xcodeCleaner: return "hammer.circle"
        case .uninstaller: return "square.stack.3d.up"
        case .privacy: return "hand.raised.circle"
        case .optimization: return "bolt.circle"
        case .settings: return "gear"
        }
    }
    
    /// Group separators for visual hierarchy
    var showDividerAfter: Bool {
        switch self {
        case .dashboard, .xcodeCleaner, .optimization: return true
        default: return false
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
                        
                        Text("v2.0")
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
                    Text("Version 2.0.0")
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
        case .xcodeCleaner:
            XcodeCleanerView()
        case .uninstaller:
            UninstallerView()
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
        .frame(width: 900, height: 600)
}
