import Foundation

/// Supported browsers for privacy cleaning
enum Browser: String, CaseIterable, Identifiable {
    case safari = "Safari"
    case chrome = "Google Chrome"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .safari: return "safari"
        case .chrome: return "globe"
        }
    }
    
    var historyPath: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        switch self {
        case .safari:
            return home.appendingPathComponent("Library/Safari/History.db")
        case .chrome:
            return home.appendingPathComponent("Library/Application Support/Google/Chrome/Default/History")
        }
    }
    
    var cookiesPath: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        switch self {
        case .safari:
            return home.appendingPathComponent("Library/Cookies/Cookies.binarycookies")
        case .chrome:
            return home.appendingPathComponent("Library/Application Support/Google/Chrome/Default/Cookies")
        }
    }
}

/// Browser data type for privacy clearing
enum BrowserDataType: String, CaseIterable, Identifiable {
    case history = "Browsing History"
    case cookies = "Cookies"
    case cache = "Cache"
    case downloads = "Download History"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .history: return "clock.arrow.circlepath"
        case .cookies: return "shippingbox"
        case .cache: return "internaldrive"
        case .downloads: return "arrow.down.circle"
        }
    }
}

/// Represents browser data that can be cleared
struct BrowserData: Identifiable {
    let id = UUID()
    let browser: Browser
    let dataType: BrowserDataType
    var size: Int64 = 0
    var isSelected: Bool = false
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

/// Summary of browser data for a specific browser
struct BrowserSummary: Identifiable {
    let id = UUID()
    let browser: Browser
    var dataItems: [BrowserData]
    
    var totalSize: Int64 {
        dataItems.reduce(0) { $0 + $1.size }
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}
