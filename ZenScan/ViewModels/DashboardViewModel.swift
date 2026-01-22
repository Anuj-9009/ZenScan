import Foundation
import Combine

/// Main scan state for the dashboard
enum ScanState: Equatable {
    case idle
    case scanning(progress: Double, status: String)
    case complete
    case error(String)
    
    var isScanning: Bool {
        if case .scanning = self { return true }
        return false
    }
}

/// Dashboard ViewModel - orchestrates all scanning agents
@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var scanState: ScanState = .idle
    @Published var totalJunkSize: Int64 = 0
    @Published var totalAppsCount: Int = 0
    @Published var totalBrowserDataSize: Int64 = 0
    @Published var loginItemsCount: Int = 0
    
    // Results from scans
    @Published var junkGroups: [JunkGroup] = []
    @Published var installedApps: [InstalledApp] = []
    @Published var browserSummaries: [BrowserSummary] = []
    @Published var processItems: [ProcessCategory: [ProcessItem]] = [:]
    
    // MARK: - Agents
    private let systemJunkAgent = SystemJunkAgent()
    private let applicationAgent = ApplicationAgent()
    private let browserDataAgent = BrowserDataAgent()
    private let processAgent = ProcessAgent()
    
    // MARK: - Smart Scan
    
    /// Perform a complete system scan
    func performSmartScan() async {
        scanState = .scanning(progress: 0, status: "Starting scan...")
        
        // Phase 1: System Junk (25%)
        junkGroups = await systemJunkAgent.scanForJunk { [weak self] progress, status in
            Task { @MainActor in
                self?.scanState = .scanning(progress: progress * 0.25, status: status)
            }
        }
        totalJunkSize = await systemJunkAgent.totalJunkSize(in: junkGroups)
        
        // Phase 2: Applications (50%)
        scanState = .scanning(progress: 0.25, status: "Scanning applications...")
        installedApps = await applicationAgent.scanApplications { [weak self] progress, status in
            Task { @MainActor in
                self?.scanState = .scanning(progress: 0.25 + progress * 0.25, status: status)
            }
        }
        totalAppsCount = installedApps.count
        
        // Phase 3: Browser Data (75%)
        scanState = .scanning(progress: 0.50, status: "Analyzing browser data...")
        browserSummaries = await browserDataAgent.scanBrowserData { [weak self] progress, status in
            Task { @MainActor in
                self?.scanState = .scanning(progress: 0.50 + progress * 0.25, status: status)
            }
        }
        totalBrowserDataSize = browserSummaries.reduce(0) { $0 + $1.totalSize }
        
        // Phase 4: Processes (100%)
        scanState = .scanning(progress: 0.75, status: "Checking startup items...")
        processItems = await processAgent.scanProcesses { [weak self] progress, status in
            Task { @MainActor in
                self?.scanState = .scanning(progress: 0.75 + progress * 0.25, status: status)
            }
        }
        loginItemsCount = processItems[.loginItems]?.count ?? 0
        
        scanState = .complete
    }
    
    /// Reset scan state
    func resetScan() {
        scanState = .idle
        totalJunkSize = 0
        totalAppsCount = 0
        totalBrowserDataSize = 0
        loginItemsCount = 0
        junkGroups = []
        installedApps = []
        browserSummaries = []
        processItems = [:]
    }
    
    // MARK: - Cleanup Actions
    
    /// Clean selected junk items
    func cleanSelectedJunk() async -> (deleted: Int, failed: Int) {
        let selectedItems = junkGroups.flatMap { $0.items.filter { $0.isSelected } }
        return (try? await systemJunkAgent.deleteItems(selectedItems)) ?? (0, selectedItems.count)
    }
    
    /// Get formatted total junk size
    var formattedJunkSize: String {
        ByteCountFormatter.string(fromByteCount: totalJunkSize, countStyle: .file)
    }
    
    /// Get formatted browser data size
    var formattedBrowserDataSize: String {
        ByteCountFormatter.string(fromByteCount: totalBrowserDataSize, countStyle: .file)
    }
}
