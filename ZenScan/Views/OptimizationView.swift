import SwiftUI

/// Optimization module view
struct OptimizationView: View {
    @StateObject private var viewModel = OptimizationViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
                .background(Color.slateGray.opacity(0.3))
            
            // Content
            if viewModel.isScanning {
                scanningView
            } else if viewModel.processItems.isEmpty {
                emptyState
            } else {
                processContent
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Optimization")
                    .font(.title.weight(.bold))
                    .foregroundColor(.frostWhite)
                
                Text("Manage login items and background processes")
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
            
            // Stats
            if !viewModel.processItems.isEmpty {
                HStack(spacing: 24) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(viewModel.loginItemsCount)")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.emeraldGreen)
                        Text("Login Items")
                            .font(.caption)
                            .foregroundColor(.slateGray)
                    }
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(viewModel.backgroundProcessCount)")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.emeraldGreen)
                        Text("Background")
                            .font(.caption)
                            .foregroundColor(.slateGray)
                    }
                }
            }
            
            Button {
                Task {
                    await viewModel.scan()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundColor(.emeraldGreen)
        }
        .padding(24)
    }
    
    private var scanningView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressRing(progress: viewModel.scanProgress, lineWidth: 8, size: 120)
            
            Text(viewModel.statusText)
                .font(.headline)
                .foregroundColor(.slateGray)
            
            Spacer()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bolt.circle")
                .font(.system(size: 60))
                .foregroundColor(.slateGray)
            
            Text("Scan to find startup items and background processes")
                .font(.headline)
                .foregroundColor(.slateGray)
            
            Button {
                Task {
                    await viewModel.scan()
                }
            } label: {
                Text("Start Scan")
                    .font(.headline)
                    .foregroundColor(.frostWhite)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.accentGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
    
    private var processContent: some View {
        VStack(spacing: 0) {
            // Category picker
            categoryPicker
            
            // Process list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.currentCategoryItems) { item in
                        ProcessRow(item: item, category: viewModel.selectedCategory) {
                            Task {
                                if viewModel.selectedCategory == .loginItems {
                                    try? await viewModel.disableLoginItem(item)
                                } else {
                                    try? await viewModel.terminateProcess(item)
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
    }
    
    private var categoryPicker: some View {
        HStack(spacing: 8) {
            ForEach(ProcessCategory.allCases) { category in
                CategoryTab(
                    category: category,
                    count: viewModel.processItems[category]?.count ?? 0,
                    isSelected: viewModel.selectedCategory == category
                ) {
                    viewModel.selectedCategory = category
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

/// Category tab button
struct CategoryTab: View {
    let category: ProcessCategory
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                
                Text(category.rawValue)
                    .font(.subheadline)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.frostWhite.opacity(0.2) : Color.slateGray.opacity(0.3))
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .frostWhite : .slateGray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.emeraldGreen.opacity(0.2) : Color.clear)
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.emeraldGreen.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Process row item
struct ProcessRow: View {
    let item: ProcessItem
    let category: ProcessCategory
    let onAction: () -> Void
    
    var body: some View {
        GlassCard(padding: 12) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: item.isLoginItem ? "person.badge.key.fill" : "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.emeraldGreen)
                    .frame(width: 40)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                    
                    if let bundleId = item.bundleIdentifier {
                        Text(bundleId)
                            .font(.caption)
                            .foregroundColor(.slateGray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Action button
                Button(action: onAction) {
                    Text(category == .loginItems ? "Disable" : "Quit")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.frostWhite)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.slateGray.opacity(0.3))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    OptimizationView()
        .frame(width: 700, height: 600)
        .background(Color.backgroundGradient)
}
