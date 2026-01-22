import Foundation

/// ViewModel for Uninstaller module
@MainActor
class UninstallerViewModel: ObservableObject {
    @Published var apps: [InstalledApp] = []
    @Published var filteredApps: [InstalledApp] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var statusText = ""
    @Published var searchText = ""
    @Published var selectedCategory: AppCategory = .all
    @Published var sortBySize = true
    
    private let agent = ApplicationAgent()
    
    var selectedApps: [InstalledApp] {
        apps.filter { $0.isSelected }
    }
    
    var totalSelectedSize: Int64 {
        selectedApps.reduce(0) { $0 + $1.totalSize }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file)
    }
    
    func scan() async {
        isScanning = true
        scanProgress = 0
        statusText = "Finding applications..."
        
        apps = await agent.scanApplications { [weak self] progress, status in
            Task { @MainActor in
                self?.scanProgress = progress
                self?.statusText = status
            }
        }
        
        applyFilters()
        isScanning = false
    }
    
    func applyFilters() {
        var result = apps
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Apply category filter
        switch selectedCategory {
        case .all:
            break
        case .large:
            result = result.filter { $0.totalSize > 500_000_000 } // > 500 MB
        case .unused:
            // Would need usage data tracking
            break
        case .system:
            result = result.filter { $0.appPath.path.hasPrefix("/System") }
        }
        
        // Apply sorting
        if sortBySize {
            result = result.sorted { $0.totalSize > $1.totalSize }
        } else {
            result = result.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
        
        filteredApps = result
    }
    
    func toggleSelection(for app: InstalledApp) {
        if let index = apps.firstIndex(where: { $0.id == app.id }) {
            apps[index].isSelected.toggle()
            applyFilters()
        }
    }
    
    func uninstallSelected() async -> (deleted: Int, failed: Int) {
        var totalDeleted = 0
        var totalFailed = 0
        
        for app in selectedApps {
            do {
                let result = try await agent.uninstallApplication(app)
                totalDeleted += result.deleted
                totalFailed += result.failed
            } catch {
                totalFailed += 1
            }
        }
        
        // Refresh after uninstalling
        await scan()
        
        return (totalDeleted, totalFailed)
    }
}
