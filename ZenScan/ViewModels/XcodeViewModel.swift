import Foundation

/// ViewModel for Xcode Cache Cleaner
@MainActor
class XcodeViewModel: ObservableObject {
    @Published var items: [XcodeCacheItem] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var statusText = ""
    
    private let agent = XcodeAgent()
    
    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var selectedItems: [XcodeCacheItem] {
        items.filter { $0.isSelected }
    }
    
    var selectedSize: Int64 {
        selectedItems.reduce(0) { $0 + $1.size }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }
    
    func scan() async {
        isScanning = true
        scanProgress = 0
        statusText = "Scanning Xcode caches..."
        
        items = await agent.scanXcodeCaches { [weak self] progress, status in
            Task { @MainActor in
                self?.scanProgress = progress
                self?.statusText = status
            }
        }
        
        isScanning = false
    }
    
    func toggleSelection(for item: XcodeCacheItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isSelected.toggle()
        }
    }
    
    func selectAll() {
        for i in items.indices {
            items[i].isSelected = true
        }
    }
    
    func deselectAll() {
        for i in items.indices {
            items[i].isSelected = false
        }
    }
    
    func deleteSelected() async -> (deleted: Int, failed: Int, freedSpace: Int64) {
        let result = await agent.deleteItems(selectedItems)
        await scan()
        return result
    }
}
