import Foundation

/// ViewModel for Privacy Protector module
@MainActor
class PrivacyViewModel: ObservableObject {
    @Published var browserSummaries: [BrowserSummary] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var statusText = ""
    @Published var showBrowserRunningAlert = false
    @Published var runningBrowser: Browser?
    
    private let agent = BrowserDataAgent()
    
    var totalSelectedSize: Int64 {
        browserSummaries.flatMap { $0.dataItems.filter { $0.isSelected } }.reduce(0) { $0 + $1.size }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file)
    }
    
    func scan() async {
        isScanning = true
        scanProgress = 0
        statusText = "Scanning browser data..."
        
        browserSummaries = await agent.scanBrowserData { [weak self] progress, status in
            Task { @MainActor in
                self?.scanProgress = progress
                self?.statusText = status
            }
        }
        
        isScanning = false
    }
    
    func toggleSelection(for item: BrowserData, in summaryIndex: Int) {
        if let itemIndex = browserSummaries[summaryIndex].dataItems.firstIndex(where: { $0.id == item.id }) {
            browserSummaries[summaryIndex].dataItems[itemIndex].isSelected.toggle()
        }
    }
    
    func selectAllForBrowser(at index: Int) {
        for i in browserSummaries[index].dataItems.indices {
            browserSummaries[index].dataItems[i].isSelected = true
        }
    }
    
    func deselectAllForBrowser(at index: Int) {
        for i in browserSummaries[index].dataItems.indices {
            browserSummaries[index].dataItems[i].isSelected = false
        }
    }
    
    func clearSelected() async -> (deleted: Int, failed: Int) {
        // Check if any targeted browsers are running
        for summary in browserSummaries {
            if summary.dataItems.contains(where: { $0.isSelected }) {
                if await agent.isBrowserRunning(summary.browser) {
                    runningBrowser = summary.browser
                    showBrowserRunningAlert = true
                    return (0, 0)
                }
            }
        }
        
        let selectedItems = browserSummaries.flatMap { $0.dataItems.filter { $0.isSelected } }
        let result = await agent.clearBrowserData(selectedItems)
        
        // Refresh after clearing
        await scan()
        
        return result
    }
}
