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

/// Dashboard ViewModel - orchestrates all scanning agents with improved performance
@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var scanState: ScanState = .idle
    @Published var totalJunkSize: Int64 = 0
    @Published var totalAppsCount: Int = 0
    @Published var totalBrowserDataSize: Int64 = 0
    @Published var loginItemsCount: Int = 0
    @Published var lastScanDate: Date?
    @Published var errorMessage: String?
    
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
    
    /// Perform a complete system scan with improved error handling
    func performSmartScan() async {
        errorMessage = nil
        scanState = .scanning(progress: 0, status: "Initializing scan...")
        
        // Add a small delay to let UI update
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        do {
            // Phase 1: System Junk (25%)
            scanState = .scanning(progress: 0.05, status: "Scanning system junk...")
            
            junkGroups = await systemJunkAgent.scanForJunk { [weak self] progress, status in
                Task { @MainActor in
                    self?.scanState = .scanning(progress: progress * 0.25, status: status)
                }
            }
            totalJunkSize = await systemJunkAgent.totalJunkSize(in: junkGroups)
            
            // Phase 2: Applications (50%)
            scanState = .scanning(progress: 0.25, status: "Scanning applications...")
            try? await Task.sleep(nanoseconds: 50_000_000) // Brief pause for UI
            
            installedApps = await applicationAgent.scanApplications { [weak self] progress, status in
                Task { @MainActor in
                    self?.scanState = .scanning(progress: 0.25 + progress * 0.25, status: status)
                }
            }
            totalAppsCount = installedApps.count
            
            // Phase 3: Browser Data (75%)
            scanState = .scanning(progress: 0.50, status: "Analyzing browser data...")
            try? await Task.sleep(nanoseconds: 50_000_000)
            
            browserSummaries = await browserDataAgent.scanBrowserData { [weak self] progress, status in
                Task { @MainActor in
                    self?.scanState = .scanning(progress: 0.50 + progress * 0.25, status: status)
                }
            }
            totalBrowserDataSize = browserSummaries.reduce(0) { $0 + $1.totalSize }
            
            // Phase 4: Processes (100%)
            scanState = .scanning(progress: 0.75, status: "Checking startup items...")
            try? await Task.sleep(nanoseconds: 50_000_000)
            
            processItems = await processAgent.scanProcesses { [weak self] progress, status in
                Task { @MainActor in
                    self?.scanState = .scanning(progress: 0.75 + progress * 0.25, status: status)
                }
            }
            loginItemsCount = processItems[.loginItems]?.count ?? 0
            
            lastScanDate = Date()
            scanState = .complete
            
        } catch {
            errorMessage = error.localizedDescription
            scanState = .error(error.localizedDescription)
        }
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
        errorMessage = nil
    }
    
    // MARK: - Cleanup Actions
    
    /// Clean selected junk items
    func cleanSelectedJunk() async -> (deleted: Int, failed: Int) {
        let selectedItems = junkGroups.flatMap { $0.items.filter { $0.isSelected } }
        guard !selectedItems.isEmpty else { return (0, 0) }
        
        do {
            let result = try await systemJunkAgent.deleteItems(selectedItems)
            // Refresh after cleaning
            await performSmartScan()
            return result
        } catch {
            errorMessage = "Clean failed: \(error.localizedDescription)"
            return (0, selectedItems.count)
        }
    }
    
    /// Select all junk items
    func selectAllJunk() {
        for groupIndex in junkGroups.indices {
            for itemIndex in junkGroups[groupIndex].items.indices {
                junkGroups[groupIndex].items[itemIndex].isSelected = true
            }
        }
    }
    
    /// Deselect all junk items
    func deselectAllJunk() {
        for groupIndex in junkGroups.indices {
            for itemIndex in junkGroups[groupIndex].items.indices {
                junkGroups[groupIndex].items[itemIndex].isSelected = false
            }
        }
    }
    
    /// Get formatted total junk size
    var formattedJunkSize: String {
        ByteCountFormatter.string(fromByteCount: totalJunkSize, countStyle: .file)
    }
    
    /// Get formatted browser data size
    var formattedBrowserDataSize: String {
        ByteCountFormatter.string(fromByteCount: totalBrowserDataSize, countStyle: .file)
    }
    
    /// Check if Full Disk Access is likely granted
    var hasFullDiskAccess: Bool {
        let testPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Safari/Bookmarks.plist")
        return FileManager.default.isReadableFile(atPath: testPath.path)
    }
}
