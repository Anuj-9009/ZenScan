import SwiftUI

/// Uninstaller module view
struct UninstallerView: View {
    @StateObject private var viewModel = UninstallerViewModel()
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
                .background(Color.slateGray.opacity(0.3))
            
            // Search and filters
            searchBar
            
            // Content
            if viewModel.isScanning {
                scanningView
            } else if viewModel.apps.isEmpty {
                emptyState
            } else {
                appsList
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Uninstaller")
                    .font(.title.weight(.bold))
                    .foregroundColor(.frostWhite)
                
                Text("Remove applications and all their data")
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
            
            if !viewModel.selectedApps.isEmpty {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.formattedSelectedSize)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.emeraldGreen)
                    
                    Text("\(viewModel.selectedApps.count) apps selected")
                        .font(.caption)
                        .foregroundColor(.slateGray)
                }
                
                Button {
                    showConfirmation = true
                } label: {
                    Label("Uninstall", systemImage: "trash.fill")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentGradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            Button {
                Task {
                    await viewModel.scan()
                }
            } label: {
                Label("Scan", systemImage: "arrow.clockwise")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundColor(.emeraldGreen)
        }
        .padding(24)
    }
    
    private var searchBar: some View {
        HStack(spacing: 16) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.slateGray)
                
                TextField("Search applications...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.frostWhite)
                    .onChange(of: viewModel.searchText) { _, _ in
                        viewModel.applyFilters()
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Sort toggle
            Button {
                viewModel.sortBySize.toggle()
                viewModel.applyFilters()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.sortBySize ? "arrow.down" : "textformat.abc")
                    Text(viewModel.sortBySize ? "By Size" : "By Name")
                }
                .font(.caption)
                .foregroundColor(.slateGray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
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
            
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 60))
                .foregroundColor(.slateGray)
            
            Text("Scan to find installed applications")
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
    
    private var appsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.filteredApps) { app in
                    AppRow(app: app) {
                        viewModel.toggleSelection(for: app)
                    }
                }
            }
            .padding(24)
        }
        .alert("Uninstall Applications?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Uninstall", role: .destructive) {
                Task {
                    _ = await viewModel.uninstallSelected()
                }
            }
        } message: {
            Text("This will permanently remove \(viewModel.selectedApps.count) application(s) and free up \(viewModel.formattedSelectedSize).")
        }
    }
}

/// Application row item
struct AppRow: View {
    let app: InstalledApp
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            GlassCard(padding: 12) {
                HStack(spacing: 16) {
                    // Checkbox
                    Image(systemName: app.isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(app.isSelected ? .emeraldGreen : .slateGray)
                        .font(.title2)
                    
                    // App icon
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.slateGray.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "app.fill")
                                    .foregroundColor(.slateGray)
                            )
                    }
                    
                    // App info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.headline)
                            .foregroundColor(.frostWhite)
                        
                        Text(app.bundleIdentifier)
                            .font(.caption)
                            .foregroundColor(.slateGray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Size bubble
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(app.formattedSize)
                            .font(.headline)
                            .foregroundColor(.emeraldGreen)
                        
                        if !app.containerPaths.isEmpty {
                            Text("+\(app.containerPaths.count) containers")
                                .font(.caption2)
                                .foregroundColor(.slateGray)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    UninstallerView()
        .frame(width: 700, height: 600)
        .background(Color.backgroundGradient)
}
