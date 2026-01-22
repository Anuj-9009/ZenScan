import SwiftUI

/// Download Folder Manager view
struct DownloadManagerView: View {
    @StateObject private var viewModel = DownloadManagerViewModel()
    @State private var showDeleteConfirmation = false
    
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
                downloadList
            }
        }
        .onAppear {
            Task { await viewModel.scan() }
        }
        .alert("Delete Selected?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Move to Trash", role: .destructive) {
                Task { await viewModel.deleteSelected() }
            }
        } message: {
            Text("This will move \(viewModel.selectedCount) items (\(viewModel.formattedSelectedSize)) to Trash.")
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.emeraldGreen)
                    Text("Downloads Manager")
                        .font(.title.weight(.bold))
                        .foregroundColor(.frostWhite)
                }
                
                Text("Clean up old downloads")
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
            
            // Age filter
            HStack {
                Text("Show:")
                    .font(.caption)
                    .foregroundColor(.slateGray)
                
                Picker("", selection: $viewModel.ageFilter) {
                    Text("All").tag(0)
                    Text("> 7 days").tag(7)
                    Text("> 30 days").tag(30)
                    Text("> 90 days").tag(90)
                }
                .frame(width: 120)
                .onChange(of: viewModel.ageFilter) { _, _ in
                    viewModel.applyFilter()
                }
            }
            
            if viewModel.selectedCount > 0 {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete (\(viewModel.formattedSelectedSize))", systemImage: "trash")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            Button {
                Task { await viewModel.scan() }
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
            ProgressView()
                .scaleEffect(1.5)
            Text("Scanning Downloads...")
                .font(.headline)
                .foregroundColor(.slateGray)
            Spacer()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.emeraldGreen)
            
            Text("Downloads folder is clean!")
                .font(.headline)
                .foregroundColor(.slateGray)
            
            Spacer()
        }
    }
    
    private var downloadList: some View {
        VStack(spacing: 0) {
            // Stats bar
            HStack {
                Text("\(viewModel.filteredItems.count) items")
                    .foregroundColor(.slateGray)
                
                Text("•")
                    .foregroundColor(.slateGray)
                
                Text(viewModel.formattedTotalSize)
                    .foregroundColor(.emeraldGreen)
                
                Spacer()
                
                Button {
                    viewModel.selectAll()
                } label: {
                    Text("Select All")
                        .font(.caption)
                        .foregroundColor(.emeraldGreen)
                }
                .buttonStyle(.plain)
                
                Button {
                    viewModel.selectOld()
                } label: {
                    Text("Select Old (30+ days)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
                
                Button {
                    viewModel.deselectAll()
                } label: {
                    Text("Deselect")
                        .font(.caption)
                        .foregroundColor(.slateGray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(Color.deepSpaceBlue.opacity(0.3))
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.filteredItems) { item in
                        DownloadRow(item: item) {
                            viewModel.toggleSelection(item)
                        }
                    }
                }
                .padding(24)
            }
        }
    }
}

struct DownloadRow: View {
    let item: DownloadItem
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            GlassCard(padding: 12) {
                HStack(spacing: 12) {
                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isSelected ? .emeraldGreen : .slateGray)
                        .font(.title3)
                    
                    Image(systemName: item.icon)
                        .foregroundColor(iconColor)
                        .font(.title3)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline)
                            .foregroundColor(.frostWhite)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            Text(item.formattedDate)
                                .font(.caption)
                                .foregroundColor(ageColor)
                            
                            Text("•")
                                .foregroundColor(.slateGray)
                            
                            Text(item.formattedSize)
                                .font(.caption)
                                .foregroundColor(.slateGray)
                        }
                    }
                    
                    Spacer()
                    
                    // Age badge
                    if item.ageInDays > 30 {
                        Text("\(item.ageInDays)d")
                            .font(.caption2)
                            .foregroundColor(.frostWhite)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ageColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    var iconColor: Color {
        let ext = item.path.pathExtension.lowercased()
        switch ext {
        case "dmg", "pkg": return .blue
        case "zip", "rar": return .orange
        case "jpg", "png", "heic": return .green
        case "mp4", "mov": return .purple
        default: return .slateGray
        }
    }
    
    var ageColor: Color {
        if item.ageInDays > 90 {
            return .red
        } else if item.ageInDays > 30 {
            return .orange
        } else {
            return .slateGray
        }
    }
}

/// ViewModel for Download Manager
@MainActor
class DownloadManagerViewModel: ObservableObject {
    @Published var items: [DownloadItem] = []
    @Published var filteredItems: [DownloadItem] = []
    @Published var isScanning = false
    @Published var ageFilter = 0
    
    private let agent = DownloadAgent()
    
    var selectedCount: Int {
        items.filter { $0.isSelected }.count
    }
    
    var selectedSize: Int64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }
    
    var formattedTotalSize: String {
        let total = filteredItems.reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
    
    func scan() async {
        isScanning = true
        items = await agent.scanDownloads()
        applyFilter()
        isScanning = false
    }
    
    func applyFilter() {
        if ageFilter == 0 {
            filteredItems = items
        } else {
            filteredItems = items.filter { $0.ageInDays >= ageFilter }
        }
    }
    
    func toggleSelection(_ item: DownloadItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isSelected.toggle()
        }
        applyFilter()
    }
    
    func selectAll() {
        for i in items.indices {
            items[i].isSelected = true
        }
        applyFilter()
    }
    
    func selectOld() {
        for i in items.indices {
            items[i].isSelected = items[i].ageInDays >= 30
        }
        applyFilter()
    }
    
    func deselectAll() {
        for i in items.indices {
            items[i].isSelected = false
        }
        applyFilter()
    }
    
    func deleteSelected() async {
        let selected = items.filter { $0.isSelected }
        _ = await agent.deleteItems(selected)
        await scan()
    }
}

#Preview {
    DownloadManagerView()
        .frame(width: 700, height: 600)
        .background(Color.backgroundGradient)
}
