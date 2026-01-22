import SwiftUI

/// Xcode Cache Cleaner view
struct XcodeCleanerView: View {
    @StateObject private var viewModel = XcodeViewModel()
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .background(Color.slateGray.opacity(0.3))
            
            if viewModel.isScanning {
                scanningView
            } else if viewModel.items.isEmpty {
                emptyState
            } else {
                cacheList
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.emeraldGreen)
                    Text("Xcode Cleaner")
                        .font(.title.weight(.bold))
                        .foregroundColor(.frostWhite)
                }
                
                Text("Clean DerivedData, Archives, and Simulators")
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
            
            if !viewModel.items.isEmpty {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.formattedTotalSize)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.emeraldGreen)
                    
                    Text("Total Xcode data")
                        .font(.caption)
                        .foregroundColor(.slateGray)
                }
                
                if viewModel.selectedSize > 0 {
                    Button {
                        showConfirmation = true
                    } label: {
                        Label("Clean \(viewModel.formattedSelectedSize)", systemImage: "trash.fill")
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
            
            Button {
                Task { await viewModel.scan() }
            } label: {
                Label("Scan", systemImage: "arrow.clockwise")
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
            
            Image(systemName: "hammer.circle")
                .font(.system(size: 60))
                .foregroundColor(.slateGray)
            
            Text("Scan to find Xcode caches")
                .font(.headline)
                .foregroundColor(.slateGray)
            
            Text("Make sure Xcode is installed")
                .font(.subheadline)
                .foregroundColor(.slateGray.opacity(0.7))
            
            Button {
                Task { await viewModel.scan() }
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
    
    private var cacheList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Select all button
                HStack {
                    Button {
                        viewModel.selectAll()
                    } label: {
                        Text("Select All")
                            .font(.caption)
                            .foregroundColor(.emeraldGreen)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        viewModel.deselectAll()
                    } label: {
                        Text("Deselect All")
                            .font(.caption)
                            .foregroundColor(.slateGray)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                ForEach(viewModel.items) { item in
                    XcodeCacheRow(item: item) {
                        viewModel.toggleSelection(for: item)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
        }
        .alert("Clean Xcode Caches?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clean", role: .destructive) {
                Task { _ = await viewModel.deleteSelected() }
            }
        } message: {
            Text("This will permanently delete \(viewModel.formattedSelectedSize) of Xcode data. This action cannot be undone.")
        }
    }
}

/// Xcode cache item row
struct XcodeCacheRow: View {
    let item: XcodeCacheItem
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            GlassCard(padding: 16) {
                HStack(spacing: 16) {
                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isSelected ? .emeraldGreen : .slateGray)
                        .font(.title2)
                    
                    Image(systemName: item.icon)
                        .font(.title2)
                        .foregroundColor(.emeraldGreen)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.headline)
                            .foregroundColor(.frostWhite)
                        
                        Text(item.description)
                            .font(.caption)
                            .foregroundColor(.slateGray)
                    }
                    
                    Spacer()
                    
                    Text(item.formattedSize)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.emeraldGreen)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    XcodeCleanerView()
        .frame(width: 700, height: 600)
        .background(Color.backgroundGradient)
}
