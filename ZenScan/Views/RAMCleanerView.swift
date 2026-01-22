import SwiftUI

/// RAM Cleaner view
struct RAMCleanerView: View {
    @StateObject private var viewModel = RAMCleanerViewModel()
    @State private var showPurgeConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .background(Color.slateGray.opacity(0.3))
            
            ScrollView {
                VStack(spacing: 24) {
                    // Memory usage ring
                    memoryRing
                    
                    // Memory breakdown
                    memoryBreakdown
                    
                    // RAM Cleaner action
                    cleanerAction
                }
                .padding(24)
            }
        }
        .onAppear {
            viewModel.refresh()
        }
        .alert("Purge Inactive Memory?", isPresented: $showPurgeConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Purge", role: .destructive) {
                Task { await viewModel.purgeMemory() }
            }
        } message: {
            Text("This will free up \(viewModel.stats.formattedInactive) of inactive memory. Apps may need to reload data from disk.")
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "memorychip")
                        .foregroundColor(.emeraldGreen)
                    Text("RAM Cleaner")
                        .font(.title.weight(.bold))
                        .foregroundColor(.frostWhite)
                }
                
                Text("Monitor and optimize memory usage")
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
            
            Button {
                viewModel.refresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundColor(.emeraldGreen)
        }
        .padding(24)
    }
    
    private var memoryRing: some View {
        GlassCard {
            HStack(spacing: 40) {
                // Usage ring
                ZStack {
                    Circle()
                        .stroke(Color.slateGray.opacity(0.3), lineWidth: 20)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.stats.usagePercent)
                        .stroke(
                            pressureGradient,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: viewModel.stats.usagePercent)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(viewModel.stats.usagePercent * 100))%")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.frostWhite)
                        
                        Text("Used")
                            .font(.caption)
                            .foregroundColor(.slateGray)
                    }
                }
                .frame(width: 150, height: 150)
                
                // Stats
                VStack(alignment: .leading, spacing: 16) {
                    StatItem(
                        label: "Total Memory",
                        value: viewModel.stats.formattedTotal,
                        color: .frostWhite
                    )
                    
                    StatItem(
                        label: "Used Memory",
                        value: viewModel.stats.formattedUsed,
                        color: pressureColor
                    )
                    
                    StatItem(
                        label: "Available",
                        value: viewModel.stats.formattedAvailable,
                        color: .emeraldGreen
                    )
                    
                    StatItem(
                        label: "Inactive (Reclaimable)",
                        value: viewModel.stats.formattedInactive,
                        color: .orange
                    )
                }
            }
            .padding()
        }
    }
    
    private var pressureGradient: LinearGradient {
        let color = pressureColor
        return LinearGradient(
            colors: [color.opacity(0.8), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var pressureColor: Color {
        let usage = viewModel.stats.usagePercent
        if usage > 0.9 {
            return .red
        } else if usage > 0.75 {
            return .orange
        } else {
            return .emeraldGreen
        }
    }
    
    private var memoryBreakdown: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Memory Breakdown")
                    .font(.headline)
                    .foregroundColor(.frostWhite)
                
                MemoryBar(
                    label: "Active",
                    value: viewModel.stats.active,
                    total: viewModel.stats.total,
                    color: .blue
                )
                
                MemoryBar(
                    label: "Wired",
                    value: viewModel.stats.wired,
                    total: viewModel.stats.total,
                    color: .red
                )
                
                MemoryBar(
                    label: "Compressed",
                    value: viewModel.stats.compressed,
                    total: viewModel.stats.total,
                    color: .purple
                )
                
                MemoryBar(
                    label: "Inactive",
                    value: viewModel.stats.inactive,
                    total: viewModel.stats.total,
                    color: .orange
                )
                
                MemoryBar(
                    label: "Free",
                    value: viewModel.stats.free,
                    total: viewModel.stats.total,
                    color: .emeraldGreen
                )
            }
        }
    }
    
    private var cleanerAction: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free Up Memory")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                    
                    Text("Release \(viewModel.stats.formattedInactive) of inactive memory")
                        .font(.caption)
                        .foregroundColor(.slateGray)
                }
                
                Spacer()
                
                if viewModel.isPurging {
                    ProgressView()
                        .padding(.horizontal, 20)
                } else {
                    Button {
                        showPurgeConfirmation = true
                    } label: {
                        Text("Clean RAM")
                            .font(.headline)
                            .foregroundColor(.frostWhite)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.accentGradient)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.slateGray)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(color)
        }
    }
}

struct MemoryBar: View {
    let label: String
    let value: Int64
    let total: Int64
    let color: Color
    
    var ratio: Double {
        guard total > 0 else { return 0 }
        return Double(value) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.slateGray)
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: value, countStyle: .memory))
                    .font(.caption)
                    .foregroundColor(.frostWhite)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.slateGray.opacity(0.2))
                    
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 8)
        }
    }
}

/// ViewModel for RAM Cleaner
@MainActor
class RAMCleanerViewModel: ObservableObject {
    @Published var stats = MemoryStats(total: 0, active: 0, wired: 0, compressed: 0, inactive: 0, free: 0)
    @Published var isPurging = false
    
    private let agent = MemoryAgent()
    
    func refresh() {
        Task {
            stats = await agent.getMemoryStats()
        }
    }
    
    func purgeMemory() async {
        isPurging = true
        _ = await agent.purgeInactiveMemory()
        // Wait a moment for memory to settle
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        stats = await agent.getMemoryStats()
        isPurging = false
    }
}

#Preview {
    RAMCleanerView()
        .frame(width: 700, height: 600)
        .background(Color.backgroundGradient)
}
