import SwiftUI

/// System Junk module view
struct SystemJunkView: View {
    @StateObject private var viewModel = SystemJunkViewModel()
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
                .background(Color.slateGray.opacity(0.3))
            
            // Content
            if viewModel.isScanning {
                scanningView
            } else if viewModel.junkGroups.isEmpty {
                emptyState
            } else {
                junkList
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("System Junk")
                    .font(.title.weight(.bold))
                    .foregroundColor(.frostWhite)
                
                Text("Clean caches, logs, and broken preferences")
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
            
            if !viewModel.junkGroups.isEmpty {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.formattedSelectedSize)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.emeraldGreen)
                    
                    Text("Selected")
                        .font(.caption)
                        .foregroundColor(.slateGray)
                }
                
                Button {
                    showConfirmation = true
                } label: {
                    Label("Clean", systemImage: "trash.fill")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentGradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.totalSelectedSize == 0)
            }
            
            Button {
                Task {
                    await viewModel.scan()
                }
            } label: {
                Label("Scan", systemImage: "magnifyingglass")
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
            
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.slateGray)
            
            Text("Click Scan to find junk files")
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
    
    private var junkList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.junkGroups.enumerated()), id: \.element.id) { index, group in
                    JunkGroupCard(
                        group: group,
                        onToggleItem: { item in
                            viewModel.toggleSelection(for: item, in: index)
                        },
                        onSelectAll: {
                            viewModel.selectAll(in: index)
                        },
                        onDeselectAll: {
                            viewModel.deselectAll(in: index)
                        }
                    )
                }
            }
            .padding(24)
        }
        .alert("Clean Selected Items?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clean", role: .destructive) {
                Task {
                    _ = await viewModel.cleanSelected()
                }
            }
        } message: {
            Text("This will permanently delete \(viewModel.formattedSelectedSize) of junk files.")
        }
    }
}

/// Card for a junk category group
struct JunkGroupCard: View {
    let group: JunkGroup
    let onToggleItem: (JunkItem) -> Void
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        GlassCard(padding: 0) {
            VStack(spacing: 0) {
                // Header
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: group.category.icon)
                            .font(.title2)
                            .foregroundColor(.emeraldGreen)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.category.rawValue)
                                .font(.headline)
                                .foregroundColor(.frostWhite)
                            
                            Text("\(group.items.count) items")
                                .font(.caption)
                                .foregroundColor(.slateGray)
                        }
                        
                        Spacer()
                        
                        Text(group.formattedTotalSize)
                            .font(.headline)
                            .foregroundColor(.emeraldGreen)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.slateGray)
                            .padding(.leading, 8)
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)
                
                // Items
                if isExpanded {
                    Divider()
                        .background(Color.slateGray.opacity(0.2))
                    
                    VStack(spacing: 0) {
                        ForEach(group.items.prefix(10)) { item in
                            JunkItemRow(item: item) {
                                onToggleItem(item)
                            }
                            
                            if item.id != group.items.prefix(10).last?.id {
                                Divider()
                                    .background(Color.slateGray.opacity(0.1))
                            }
                        }
                        
                        if group.items.count > 10 {
                            Text("+ \(group.items.count - 10) more items")
                                .font(.caption)
                                .foregroundColor(.slateGray)
                                .padding(.vertical, 12)
                        }
                    }
                }
            }
        }
    }
}

/// Individual junk item row
struct JunkItemRow: View {
    let item: JunkItem
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isSelected ? .emeraldGreen : .slateGray)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline)
                        .foregroundColor(.frostWhite)
                        .lineLimit(1)
                    
                    Text(item.path.path)
                        .font(.caption2)
                        .foregroundColor(.slateGray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(item.formattedSize)
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SystemJunkView()
        .frame(width: 700, height: 600)
        .background(Color.backgroundGradient)
}
