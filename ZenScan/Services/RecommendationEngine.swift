import Foundation

/// Smart recommendations engine
class RecommendationEngine: ObservableObject {
    @Published var recommendations: [Recommendation] = []
    
    private let fileManager = FileManager.default
    
    /// Generate smart recommendations based on system state
    func generateRecommendations() async {
        var newRecommendations: [Recommendation] = []
        
        // Check Downloads folder age
        if await hasOldDownloads() {
            newRecommendations.append(Recommendation(
                id: "old_downloads",
                title: "Clean Old Downloads",
                description: "You have files older than 30 days in Downloads",
                priority: .medium,
                action: "Open Downloads Manager",
                icon: "arrow.down.circle",
                module: .downloads
            ))
        }
        
        // Check disk space
        if await isDiskSpaceLow() {
            newRecommendations.append(Recommendation(
                id: "low_disk",
                title: "Low Disk Space",
                description: "Less than 10% free space remaining",
                priority: .high,
                action: "Find Large Files",
                icon: "externaldrive.badge.exclamationmark",
                module: .largeFiles
            ))
        }
        
        // Check for Xcode if developer
        if await hasXcodeDerivedData() {
            newRecommendations.append(Recommendation(
                id: "xcode_cleanup",
                title: "Xcode Cleanup Available",
                description: "DerivedData folder is taking up space",
                priority: .low,
                action: "Open Xcode Cleaner",
                icon: "hammer.circle",
                module: .xcodeCleaner
            ))
        }
        
        // Check browser cache
        if await hasBrowserCache() {
            newRecommendations.append(Recommendation(
                id: "browser_cache",
                title: "Clear Browser Cache",
                description: "Browser data is using storage",
                priority: .low,
                action: "Open Privacy",
                icon: "globe",
                module: .privacy
            ))
        }
        
        await MainActor.run {
            self.recommendations = newRecommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
        }
    }
    
    // MARK: - Checks
    
    private func hasOldDownloads() async -> Bool {
        let downloadsPath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
        guard let contents = try? fileManager.contentsOfDirectory(at: downloadsPath, includingPropertiesForKeys: [.creationDateKey]) else {
            return false
        }
        
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        return contents.contains { url in
            guard let values = try? url.resourceValues(forKeys: [.creationDateKey]),
                  let date = values.creationDate else { return false }
            return date < thirtyDaysAgo
        }
    }
    
    private func isDiskSpaceLow() async -> Bool {
        guard let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]),
              let available = values.volumeAvailableCapacityForImportantUsage,
              let total = values.volumeTotalCapacity else {
            return false
        }
        
        let usagePercent = 1.0 - (Double(available) / Double(total))
        return usagePercent > 0.9
    }
    
    private func hasXcodeDerivedData() async -> Bool {
        let derivedDataPath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/DerivedData")
        return fileManager.fileExists(atPath: derivedDataPath.path)
    }
    
    private func hasBrowserCache() async -> Bool {
        let safariCachePath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Safari")
        return fileManager.fileExists(atPath: safariCachePath.path)
    }
}

/// Recommendation model
struct Recommendation: Identifiable {
    let id: String
    let title: String
    let description: String
    let priority: RecommendationPriority
    let action: String
    let icon: String
    let module: NavigationItem
}

/// Recommendation priority
enum RecommendationPriority: Int {
    case low = 1
    case medium = 2
    case high = 3
    
    var color: String {
        switch self {
        case .low: return "blue"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}
