import SwiftUI

/// Smart Scan Dashboard - Main landing page
struct DashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Smart Scan")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.frostWhite)
                    
                    Text("Analyze your Mac with one click")
                        .font(.subheadline)
                        .foregroundColor(.slateGray)
                }
                .padding(.top, 32)
                
                // Scan button with progress
                ZStack {
                    if case .scanning(let progress, let status) = viewModel.scanState {
                        VStack(spacing: 20) {
                            ZStack {
                                ProgressRing(progress: progress, lineWidth: 12, size: 180)
                                
                                VStack(spacing: 4) {
                                    Text("\(Int(progress * 100))%")
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundColor(.frostWhite)
                                    
                                    Text("Scanning")
                                        .font(.caption)
                                        .foregroundColor(.slateGray)
                                }
                            }
                            
                            Text(status)
                                .font(.subheadline)
                                .foregroundColor(.slateGray)
                                .animation(.easeInOut, value: status)
                        }
                    } else {
                        ScanButton(isScanning: viewModel.scanState.isScanning) {
                            Task {
                                await viewModel.performSmartScan()
                            }
                        }
                    }
                }
                .frame(height: 220)
                
                // Results section (shown after scan)
                if viewModel.scanState == .complete {
                    resultsSection
                }
                
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 32)
        }
    }
    
    /// Results grid after scan completion
    private var resultsSection: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Scan Results")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.frostWhite)
                
                Spacer()
                
                Button {
                    viewModel.resetScan()
                } label: {
                    Label("Scan Again", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundColor(.emeraldGreen)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                StatCard(
                    icon: "trash.slash.circle.fill",
                    title: "System Junk",
                    value: viewModel.formattedJunkSize,
                    subtitle: "\(viewModel.junkGroups.flatMap { $0.items }.count) items found"
                )
                
                StatCard(
                    icon: "square.stack.3d.up.fill",
                    title: "Applications",
                    value: "\(viewModel.totalAppsCount)",
                    subtitle: "Installed on your Mac"
                )
                
                StatCard(
                    icon: "hand.raised.circle.fill",
                    title: "Browser Data",
                    value: viewModel.formattedBrowserDataSize,
                    subtitle: "Safari & Chrome data"
                )
                
                StatCard(
                    icon: "bolt.circle.fill",
                    title: "Login Items",
                    value: "\(viewModel.loginItemsCount)",
                    subtitle: "Startup programs"
                )
            }
            
            // Quick action button
            if viewModel.totalJunkSize > 0 {
                Button {
                    Task {
                        _ = await viewModel.cleanSelectedJunk()
                    }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Clean \(viewModel.formattedJunkSize)")
                    }
                    .font(.headline)
                    .foregroundColor(.frostWhite)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.accentGradient)
                    .clipShape(Capsule())
                    .shadow(color: .emeraldGreen.opacity(0.4), radius: 10)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.scanState)
    }
}

#Preview {
    DashboardView()
        .environmentObject(DashboardViewModel())
        .frame(width: 700, height: 700)
        .background(Color.backgroundGradient)
}
