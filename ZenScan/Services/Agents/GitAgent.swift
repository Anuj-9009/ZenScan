import Foundation

/// Agent for finding Git repositories and their sizes
actor GitAgent {
    private let fileManager = FileManager.default
    
    /// Default search paths
    private var defaultSearchPaths: [URL] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent("Projects"),
            home.appendingPathComponent("Developer"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Desktop"),
        ]
    }
    
    /// Find all Git repositories
    func findRepositories(in searchPaths: [URL]? = nil, progress: @escaping (Double, String) -> Void) async -> [GitRepository] {
        let paths = searchPaths ?? defaultSearchPaths
        
        await MainActor.run { progress(0, "Searching for Git repositories...") }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var results: [GitRepository] = []
                let totalPaths = Double(max(paths.count, 1))
                
                for (index, searchPath) in paths.enumerated() {
                    guard self.fileManager.isReadableFile(atPath: searchPath.path) else { continue }
                    
                    DispatchQueue.main.async {
                        progress(Double(index) / totalPaths, "Searching \(searchPath.lastPathComponent)...")
                    }
                    
                    guard let enumerator = self.fileManager.enumerator(
                        at: searchPath,
                        includingPropertiesForKeys: [.isDirectoryKey],
                        options: [.skipsHiddenFiles],
                        errorHandler: { _, _ in true }
                    ) else { continue }
                    
                    var count = 0
                    for case let url as URL in enumerator {
                        count += 1
                        if count > 20000 { break } // Limit search
                        
                        // Check for .git directory
                        let gitPath = url.appendingPathComponent(".git")
                        if self.fileManager.fileExists(atPath: gitPath.path) {
                            enumerator.skipDescendants()
                            
                            // Calculate .git size
                            var gitSize: Int64 = 0
                            if let gitEnumerator = self.fileManager.enumerator(
                                at: gitPath,
                                includingPropertiesForKeys: [.fileSizeKey],
                                options: [],
                                errorHandler: { _, _ in true }
                            ) {
                                for case let fileURL as URL in gitEnumerator {
                                    if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]) {
                                        gitSize += Int64(values.fileSize ?? 0)
                                    }
                                }
                            }
                            
                            // Get repo info
                            let repo = self.getRepoInfo(at: url, gitSize: gitSize)
                            results.append(repo)
                        }
                    }
                }
                
                DispatchQueue.main.async { progress(1.0, "Found \(results.count) repositories") }
                continuation.resume(returning: results.sorted { $0.gitSize > $1.gitSize })
            }
        }
    }
    
    /// Get repository info
    private func getRepoInfo(at path: URL, gitSize: Int64) -> GitRepository {
        var repo = GitRepository(
            path: path,
            name: path.lastPathComponent,
            gitSize: gitSize
        )
        
        // Get current branch
        let headPath = path.appendingPathComponent(".git/HEAD")
        if let headContent = try? String(contentsOf: headPath, encoding: .utf8) {
            if headContent.hasPrefix("ref: refs/heads/") {
                repo.currentBranch = headContent
                    .replacingOccurrences(of: "ref: refs/heads/", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Get remote origin
        let configPath = path.appendingPathComponent(".git/config")
        if let configContent = try? String(contentsOf: configPath, encoding: .utf8) {
            if let urlRange = configContent.range(of: "url = ") {
                let urlStart = configContent[urlRange.upperBound...]
                if let lineEnd = urlStart.firstIndex(of: "\n") {
                    repo.remoteURL = String(urlStart[..<lineEnd])
                }
            }
        }
        
        // Get last commit date
        let logsPath = path.appendingPathComponent(".git/logs/HEAD")
        if let attr = try? fileManager.attributesOfItem(atPath: logsPath.path) {
            repo.lastCommitDate = attr[.modificationDate] as? Date
        }
        
        return repo
    }
    
    /// Clean Git repository (gc + prune)
    func cleanRepository(_ repo: GitRepository) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.currentDirectoryURL = repo.path
                process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
                process.arguments = ["gc", "--prune=now", "--aggressive"]
                process.standardOutput = FileHandle.nullDevice
                process.standardError = FileHandle.nullDevice
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    continuation.resume(returning: process.terminationStatus == 0)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    /// Get total git storage for selected repos
    func totalSize(of repos: [GitRepository]) -> Int64 {
        repos.reduce(0) { $0 + $1.gitSize }
    }
}

/// Git repository model
struct GitRepository: Identifiable {
    let id = UUID()
    let path: URL
    let name: String
    let gitSize: Int64
    var currentBranch: String = "main"
    var remoteURL: String?
    var lastCommitDate: Date?
    var isSelected: Bool = false
    
    var formattedGitSize: String {
        ByteCountFormatter.string(fromByteCount: gitSize, countStyle: .file)
    }
    
    var formattedLastCommit: String {
        guard let date = lastCommitDate else { return "Unknown" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var isGitHub: Bool {
        remoteURL?.contains("github.com") ?? false
    }
    
    var isGitLab: Bool {
        remoteURL?.contains("gitlab.com") ?? false
    }
}
