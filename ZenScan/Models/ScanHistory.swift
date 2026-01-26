import Foundation

/// Model for storing scan history
struct ScanHistoryEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let junkFound: Int64
    let junkCleaned: Int64
    let duplicatesFound: Int
    let largeFilesFound: Int
    let duration: TimeInterval
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        junkFound: Int64,
        junkCleaned: Int64 = 0,
        duplicatesFound: Int = 0,
        largeFilesFound: Int = 0,
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.date = date
        self.junkFound = junkFound
        self.junkCleaned = junkCleaned
        self.duplicatesFound = duplicatesFound
        self.largeFilesFound = largeFilesFound
        self.duration = duration
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedJunkFound: String {
        ByteCountFormatter.string(fromByteCount: junkFound, countStyle: .file)
    }
    
    var formattedJunkCleaned: String {
        ByteCountFormatter.string(fromByteCount: junkCleaned, countStyle: .file)
    }
}

/// Manager for scan history persistence
class ScanHistoryManager: ObservableObject {
    @Published var history: [ScanHistoryEntry] = []
    
    private let storageKey = "scanHistory"
    private let maxEntries = 30
    
    init() {
        load()
    }
    
    /// Add a new scan entry
    func addEntry(_ entry: ScanHistoryEntry) {
        history.insert(entry, at: 0)
        
        // Limit history size
        if history.count > maxEntries {
            history = Array(history.prefix(maxEntries))
        }
        
        save()
    }
    
    /// Get entries for the last N days
    func entriesForDays(_ days: Int) -> [ScanHistoryEntry] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
        return history.filter { $0.date >= cutoff }
    }
    
    /// Get total cleaned in last 30 days
    var totalCleanedLast30Days: Int64 {
        entriesForDays(30).reduce(0) { $0 + $1.junkCleaned }
    }
    
    /// Average junk found per scan
    var averageJunkFound: Int64 {
        guard !history.isEmpty else { return 0 }
        return history.reduce(0) { $0 + $1.junkFound } / Int64(history.count)
    }
    
    /// Clear all history
    func clearHistory() {
        history = []
        save()
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ScanHistoryEntry].self, from: data) {
            history = decoded
        }
    }
}
