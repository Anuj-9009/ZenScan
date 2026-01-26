import Foundation

/// Manager for scheduled automatic scans
class ScheduleManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "scheduleEnabled") }
    }
    @Published var frequency: ScanFrequency {
        didSet { UserDefaults.standard.set(frequency.rawValue, forKey: "scheduleFrequency") }
    }
    @Published var lastScheduledScan: Date? {
        didSet { UserDefaults.standard.set(lastScheduledScan, forKey: "lastScheduledScan") }
    }
    @Published var nextScheduledScan: Date?
    
    private var timer: Timer?
    
    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "scheduleEnabled")
        self.frequency = ScanFrequency(rawValue: UserDefaults.standard.string(forKey: "scheduleFrequency") ?? "weekly") ?? .weekly
        self.lastScheduledScan = UserDefaults.standard.object(forKey: "lastScheduledScan") as? Date
        calculateNextScan()
    }
    
    /// Calculate next scan date
    private func calculateNextScan() {
        guard isEnabled else {
            nextScheduledScan = nil
            return
        }
        
        let calendar = Calendar.current
        let lastScan = lastScheduledScan ?? Date()
        
        switch frequency {
        case .daily:
            nextScheduledScan = calendar.date(byAdding: .day, value: 1, to: lastScan)
        case .weekly:
            nextScheduledScan = calendar.date(byAdding: .weekOfYear, value: 1, to: lastScan)
        case .monthly:
            nextScheduledScan = calendar.date(byAdding: .month, value: 1, to: lastScan)
        }
    }
    
    /// Check if scan is due
    var isScanDue: Bool {
        guard isEnabled, let next = nextScheduledScan else { return false }
        return Date() >= next
    }
    
    /// Record that a scan was performed
    func recordScan() {
        lastScheduledScan = Date()
        calculateNextScan()
    }
    
    /// Format next scan date
    var formattedNextScan: String {
        guard let next = nextScheduledScan else { return "Not scheduled" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: next, relativeTo: Date())
    }
}

/// Scan frequency options
enum ScanFrequency: String, CaseIterable, Identifiable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}
