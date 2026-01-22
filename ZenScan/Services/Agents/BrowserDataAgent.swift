import Foundation
import AppKit

/// Agent responsible for managing browser privacy data
actor BrowserDataAgent {
    private let fileSystemAgent = FileSystemAgent()
    private let fileManager = FileManager.default
    
    /// Scan all supported browsers for data
    func scanBrowserData(progress: @escaping (Double, String) -> Void) async -> [BrowserSummary] {
        var summaries: [BrowserSummary] = []
        let browsers = Browser.allCases
        
        for (index, browser) in browsers.enumerated() {
            progress(Double(index) / Double(browsers.count), "Scanning \(browser.rawValue)...")
            
            var dataItems: [BrowserData] = []
            
            // Check history
            if let historySize = await getFileSize(at: browser.historyPath) {
                dataItems.append(BrowserData(
                    browser: browser,
                    dataType: .history,
                    size: historySize
                ))
            }
            
            // Check cookies
            if let cookiesSize = await getFileSize(at: browser.cookiesPath) {
                dataItems.append(BrowserData(
                    browser: browser,
                    dataType: .cookies,
                    size: cookiesSize
                ))
            }
            
            // Check cache
            if let cachePath = getCachePath(for: browser) {
                if let cacheSize = try? await fileSystemAgent.fileSize(at: cachePath) {
                    dataItems.append(BrowserData(
                        browser: browser,
                        dataType: .cache,
                        size: cacheSize
                    ))
                }
            }
            
            if !dataItems.isEmpty {
                summaries.append(BrowserSummary(browser: browser, dataItems: dataItems))
            }
        }
        
        progress(1.0, "Scan complete")
        return summaries
    }
    
    /// Get cache path for a browser
    private func getCachePath(for browser: Browser) -> URL? {
        let home = fileManager.homeDirectoryForCurrentUser
        switch browser {
        case .safari:
            return home.appendingPathComponent("Library/Caches/com.apple.Safari")
        case .chrome:
            return home.appendingPathComponent("Library/Caches/Google/Chrome")
        }
    }
    
    /// Get file size safely
    private func getFileSize(at url: URL) async -> Int64? {
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        return try? await fileSystemAgent.fileSize(at: url)
    }
    
    /// Clear browser data
    func clearBrowserData(_ items: [BrowserData]) async -> (deleted: Int, failed: Int) {
        var deleted = 0
        var failed = 0
        
        for item in items {
            do {
                let path = getDataPath(for: item)
                if fileManager.fileExists(atPath: path.path) {
                    try await fileSystemAgent.delete(at: path)
                    deleted += 1
                }
            } catch {
                failed += 1
            }
        }
        
        return (deleted, failed)
    }
    
    /// Get the file path for a specific browser data item
    private func getDataPath(for item: BrowserData) -> URL {
        switch item.dataType {
        case .history:
            return item.browser.historyPath
        case .cookies:
            return item.browser.cookiesPath
        case .cache:
            return getCachePath(for: item.browser) ?? item.browser.historyPath
        case .downloads:
            return item.browser.historyPath // Downloads are in history DB
        }
    }
    
    /// Check if a browser is currently running
    func isBrowserRunning(_ browser: Browser) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        let bundleId = browser == .safari ? "com.apple.Safari" : "com.google.Chrome"
        return runningApps.contains { $0.bundleIdentifier == bundleId }
    }
}
