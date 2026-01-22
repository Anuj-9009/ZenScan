import SwiftUI

/// Disk Space Visualizer view
struct DiskVisualizerView: View {
    @StateObject private var viewModel = DiskVisualizerViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .background(Color.slateGray.opacity(0.3))
            
            if viewModel.isScanning {
                scanningView
            } else if viewModel.rootItem == nil {
                emptyState
            } else {
                visualizerContent
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "square.grid.3x3.fill")
                        .foregroundColor(.emeraldGreen)
                    Text("Disk Visualizer")
                        .font(.title.weight(.bold))
                        .foregroundColor(.frostWhite)
                }
                
                Text("Visualize disk usage with an interactive treemap")
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
            
            // Breadcrumb navigation
            if !viewModel.navigationStack.isEmpty {
                HStack(spacing: 4) {
                    Button {
                        viewModel.navigateToRoot()
                    } label: {
                        Image(systemName: "house")
                            .foregroundColor(.emeraldGreen)
                    }
                    .buttonStyle(.plain)
                    
                    ForEach(viewModel.navigationStack.suffix(3), id: \.id) { item in
                        Text("/")
                            .foregroundColor(.slateGray)
                        Button(item.name) {
                            viewModel.navigateTo(item)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.emeraldGreen)
                        .lineLimit(1)
                    }
                }
                .font(.caption)
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
            ProgressView()
                .scaleEffect(1.5)
            Text(viewModel.statusText)
                .font(.headline)
                .foregroundColor(.slateGray)
            Spacer()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "internaldrive")
                .font(.system(size: 60))
                .foregroundColor(.slateGray)
            
            Text("Visualize your disk usage")
                .font(.headline)
                .foregroundColor(.slateGray)
            
            Text("Select a folder to analyze")
                .font(.subheadline)
                .foregroundColor(.slateGray.opacity(0.7))
            
            HStack(spacing: 16) {
                Button {
                    Task { await viewModel.scanHome() }
                } label: {
                    Label("Home Folder", systemImage: "house")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentGradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Button {
                    viewModel.selectFolder()
                } label: {
                    Label("Choose Folder", systemImage: "folder")
                        .font(.headline)
                        .foregroundColor(.emeraldGreen)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.emeraldGreen.opacity(0.2))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
    }
    
    private var visualizerContent: some View {
        VStack(spacing: 0) {
            // Stats bar
            if let root = viewModel.currentItem {
                HStack {
                    Text(root.name)
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                    
                    Spacer()
                    
                    Text(root.formattedSize)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.emeraldGreen)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.deepSpaceBlue.opacity(0.5))
            }
            
            // Treemap
            if let items = viewModel.currentItem?.children, !items.isEmpty {
                TreemapView(
                    items: items,
                    totalSize: viewModel.currentItem?.size ?? 0,
                    onSelect: { item in
                        if item.isDirectory {
                            viewModel.drillDown(into: item)
                        }
                    }
                )
                .padding(24)
            } else {
                Text("No items to display")
                    .foregroundColor(.slateGray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Legend
            legendView
        }
    }
    
    private var legendView: some View {
        HStack(spacing: 16) {
            LegendItem(color: .blue, label: "Apps")
            LegendItem(color: .orange, label: "Archives")
            LegendItem(color: .purple, label: "Videos")
            LegendItem(color: .pink, label: "Audio")
            LegendItem(color: .green, label: "Images")
            LegendItem(color: .red, label: "Documents")
            LegendItem(color: .gray, label: "Other")
        }
        .font(.caption)
        .padding()
        .background(Color.deepSpaceBlue.opacity(0.3))
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .foregroundColor(.slateGray)
        }
    }
}

/// ViewModel for Disk Visualizer
@MainActor
class DiskVisualizerViewModel: ObservableObject {
    @Published var rootItem: DiskSpaceItem?
    @Published var currentItem: DiskSpaceItem?
    @Published var navigationStack: [DiskSpaceItem] = []
    @Published var isScanning = false
    @Published var statusText = ""
    
    private let agent = DiskSpaceAgent()
    
    func scan() async {
        await scanHome()
    }
    
    func scanHome() async {
        let home = FileManager.default.homeDirectoryForCurrentUser
        await scanDirectory(at: home)
    }
    
    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await scanDirectory(at: url)
            }
        }
    }
    
    private func scanDirectory(at url: URL) async {
        isScanning = true
        statusText = "Analyzing..."
        navigationStack = []
        
        rootItem = await agent.analyzeDirectory(at: url, depth: 2) { [weak self] status in
            Task { @MainActor in
                self?.statusText = status
            }
        }
        
        currentItem = rootItem
        isScanning = false
    }
    
    func drillDown(into item: DiskSpaceItem) {
        if let current = currentItem {
            navigationStack.append(current)
        }
        currentItem = item
    }
    
    func navigateTo(_ item: DiskSpaceItem) {
        if let index = navigationStack.firstIndex(where: { $0.id == item.id }) {
            currentItem = item
            navigationStack = Array(navigationStack.prefix(index))
        }
    }
    
    func navigateToRoot() {
        currentItem = rootItem
        navigationStack = []
    }
}

#Preview {
    DiskVisualizerView()
        .frame(width: 800, height: 600)
        .background(Color.backgroundGradient)
}
