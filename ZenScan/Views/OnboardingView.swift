import SwiftUI

/// Onboarding view for first-launch experience
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    private let pages = [
        OnboardingPage(
            icon: "sparkles",
            title: "Welcome to ZenScan",
            description: "Keep your Mac clean, fast, and secure with powerful system maintenance tools."
        ),
        OnboardingPage(
            icon: "trash.slash.circle",
            title: "Smart Cleaning",
            description: "Find and remove system junk, caches, logs, and unnecessary files to free up disk space."
        ),
        OnboardingPage(
            icon: "lock.shield",
            title: "Privacy Protection",
            description: "Clear browser history, cookies, and cache from Safari and Chrome to protect your privacy."
        ),
        OnboardingPage(
            icon: "hand.raised.circle",
            title: "Full Disk Access Required",
            description: "To scan protected system folders, ZenScan needs Full Disk Access permission."
        ),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pageView(for: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.automatic)
            .frame(height: 350)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.emeraldGreen : Color.slateGray.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 24)
            
            // Actions
            if currentPage == pages.count - 1 {
                // Last page - show permission setup
                VStack(spacing: 16) {
                    Button {
                        openSystemPreferences()
                    } label: {
                        HStack {
                            Image(systemName: "gear")
                            Text("Open System Settings")
                        }
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        isPresented = false
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    } label: {
                        Text("I'll do this later")
                            .font(.subheadline)
                            .foregroundColor(.slateGray)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
            } else {
                // Navigation buttons
                HStack {
                    Button {
                        isPresented = false
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    } label: {
                        Text("Skip")
                            .foregroundColor(.slateGray)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        HStack {
                            Text("Next")
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.emeraldGreen)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
                .frame(height: 40)
        }
        .frame(width: 500, height: 500)
        .background(Color.deepSpaceBlue)
    }
    
    private func pageView(for page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(.emeraldGreen)
            
            Text(page.title)
                .font(.title.weight(.bold))
                .foregroundColor(.frostWhite)
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.body)
                .foregroundColor(.slateGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
}

/// Onboarding page data
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}

/// Check if onboarding has been completed
struct OnboardingManager {
    static var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    static func reset() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
