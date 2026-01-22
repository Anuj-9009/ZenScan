import Foundation

/// Represents a process or login item
struct ProcessItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String?
    let path: URL?
    var isLoginItem: Bool
    var isEnabled: Bool = true
    var memoryUsage: Int64 = 0
    
    var formattedMemory: String {
        ByteCountFormatter.string(fromByteCount: memoryUsage, countStyle: .memory)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ProcessItem, rhs: ProcessItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Process category types
enum ProcessCategory: String, CaseIterable, Identifiable {
    case loginItems = "Login Items"
    case backgroundProcesses = "Background Processes"
    case launchAgents = "Launch Agents"
    case launchDaemons = "Launch Daemons"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .loginItems: return "person.badge.key"
        case .backgroundProcesses: return "gearshape.2"
        case .launchAgents: return "bolt.circle"
        case .launchDaemons: return "server.rack"
        }
    }
    
    var description: String {
        switch self {
        case .loginItems: return "Apps that start when you log in"
        case .backgroundProcesses: return "Currently running background apps"
        case .launchAgents: return "User-level background services"
        case .launchDaemons: return "System-level background services"
        }
    }
}
