import Foundation

/// ViewModel for System Junk module
@MainActor
class SystemJunkViewModel: ObservableObject {
    @Published var junkGroups: [JunkGroup] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var statusText = ""
    
    private let agent = SystemJunkAgent()
    
    var totalSelectedSize: Int64 {
        junkGroups.reduce(0) { $0 + $1.selectedSize }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file)
    }
    
    var totalSize: Int64 {
        junkGroups.reduce(0) { $0 + $1.totalSize }
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    func scan() async {
        isScanning = true
        scanProgress = 0
        statusText = "Starting scan..."
        
        junkGroups = await agent.scanForJunk { [weak self] progress, status in
            Task { @MainActor in
                self?.scanProgress = progress
                self?.statusText = status
            }
        }
        
        isScanning = false
    }
    
    func toggleSelection(for item: JunkItem, in groupIndex: Int) {
        if let itemIndex = junkGroups[groupIndex].items.firstIndex(where: { $0.id == item.id }) {
            junkGroups[groupIndex].items[itemIndex].isSelected.toggle()
        }
    }
    
    func selectAll(in groupIndex: Int) {
        for i in junkGroups[groupIndex].items.indices {
            junkGroups[groupIndex].items[i].isSelected = true
        }
    }
    
    func deselectAll(in groupIndex: Int) {
        for i in junkGroups[groupIndex].items.indices {
            junkGroups[groupIndex].items[i].isSelected = false
        }
    }
    
    func cleanSelected() async -> (deleted: Int, failed: Int) {
        let selectedItems = junkGroups.flatMap { $0.items.filter { $0.isSelected } }
        let result = (try? await agent.deleteItems(selectedItems)) ?? (0, selectedItems.count)
        
        // Refresh after cleaning
        await scan()
        
        return result
    }
}
