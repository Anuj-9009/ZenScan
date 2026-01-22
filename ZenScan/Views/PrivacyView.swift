import SwiftUI

/// Privacy Protector module view
struct PrivacyView: View {
    @StateObject private var viewModel = PrivacyViewModel()
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
            } else if viewModel.browserSummaries.isEmpty {
                emptyState
            } else {
                browserList
            }
        }
        .alert("Browser Running", isPresented: $viewModel.showBrowserRunningAlert) {
            Button("OK") { }
        } message: {
            if let browser = viewModel.runningBrowser {
                Text("Please quit \(browser.rawValue) before clearing its data.")
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Privacy Protector")
                    .font(.title.weight(.bold))
                    .foregroundColor(.frostWhite)
                
                Text("Clear browser history, cookies, and cache")
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
            
            if viewModel.totalSelectedSize > 0 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.formattedSelectedSize)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.emeraldGreen)
                    
                    Text("To clear")
                        .font(.caption)
                        .foregroundColor(.slateGray)
                }
                
                Button {
                    showConfirmation = true
                } label: {
                    Label("Clear", systemImage: "hand.raised.fill")
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
            
            Image(systemName: "hand.raised.circle")
                .font(.system(size: 60))
                .foregroundColor(.slateGray)
            
            Text("Scan to find browser data")
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
    
    private var browserList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.browserSummaries.enumerated()), id: \.element.id) { index, summary in
                    BrowserCard(
                        summary: summary,
                        onToggleItem: { item in
                            viewModel.toggleSelection(for: item, in: index)
                        },
                        onSelectAll: {
                            viewModel.selectAllForBrowser(at: index)
                        },
                        onDeselectAll: {
                            viewModel.deselectAllForBrowser(at: index)
                        }
                    )
                }
            }
            .padding(24)
        }
        .alert("Clear Browser Data?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task {
                    _ = await viewModel.clearSelected()
                }
            }
        } message: {
            Text("This will permanently delete \(viewModel.formattedSelectedSize) of browser data.")
        }
    }
}

/// Browser data card
struct BrowserCard: View {
    let summary: BrowserSummary
    let onToggleItem: (BrowserData) -> Void
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
                        Image(systemName: summary.browser.icon)
                            .font(.title2)
                            .foregroundColor(.emeraldGreen)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(summary.browser.rawValue)
                                .font(.headline)
                                .foregroundColor(.frostWhite)
                            
                            Text("\(summary.dataItems.count) data types")
                                .font(.caption)
                                .foregroundColor(.slateGray)
                        }
                        
                        Spacer()
                        
                        Text(summary.formattedSize)
                            .font(.headline)
                            .foregroundColor(.emeraldGreen)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.slateGray)
                            .padding(.leading, 8)
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)
                
                // Data items
                if isExpanded {
                    Divider()
                        .background(Color.slateGray.opacity(0.2))
                    
                    VStack(spacing: 0) {
                        ForEach(summary.dataItems) { item in
                            BrowserDataRow(item: item) {
                                onToggleItem(item)
                            }
                            
                            if item.id != summary.dataItems.last?.id {
                                Divider()
                                    .background(Color.slateGray.opacity(0.1))
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Browser data type row
struct BrowserDataRow: View {
    let item: BrowserData
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isSelected ? .emeraldGreen : .slateGray)
                    .font(.title3)
                
                Image(systemName: item.dataType.icon)
                    .foregroundColor(.slateGray)
                    .frame(width: 24)
                
                Text(item.dataType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.frostWhite)
                
                Spacer()
                
                Text(item.formattedSize)
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PrivacyView()
        .frame(width: 700, height: 600)
        .background(Color.backgroundGradient)
}
