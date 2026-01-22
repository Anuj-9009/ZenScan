import Foundation

/// ViewModel for Optimization module
@MainActor
class OptimizationViewModel: ObservableObject {
    @Published var processItems: [ProcessCategory: [ProcessItem]] = [:]
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var statusText = ""
    @Published var selectedCategory: ProcessCategory = .loginItems
    
    private let agent = ProcessAgent()
    
    var currentCategoryItems: [ProcessItem] {
        processItems[selectedCategory] ?? []
    }
    
    var loginItemsCount: Int {
        processItems[.loginItems]?.count ?? 0
    }
    
    var backgroundProcessCount: Int {
        processItems[.backgroundProcesses]?.count ?? 0
    }
    
    func scan() async {
        isScanning = true
        scanProgress = 0
        statusText = "Scanning startup items..."
        
        processItems = await agent.scanProcesses { [weak self] progress, status in
            Task { @MainActor in
                self?.scanProgress = progress
                self?.statusText = status
            }
        }
        
        isScanning = false
    }
    
    func disableLoginItem(_ item: ProcessItem) async throws {
        try await agent.disableLoginItem(item)
        
        // Refresh
        await scan()
    }
    
    func terminateProcess(_ item: ProcessItem) async throws {
        try await agent.terminateProcess(item)
        
        // Refresh
        await scan()
    }
}
