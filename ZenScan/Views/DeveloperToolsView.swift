import SwiftUI

/// Unified Developer Tools view with tabs for all dev tools
struct DeveloperToolsView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .background(Color.slateGray.opacity(0.3))
            
            // Tab bar
            tabBar
            
            // Content
            TabView(selection: $selectedTab) {
                HomebrewTabView()
                    .tag(0)
                
                NodeTabView()
                    .tag(1)
                
                DockerTabView()
                    .tag(2)
                
                GitTabView()
                    .tag(3)
            }
            .tabViewStyle(.automatic)
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.emeraldGreen)
                    Text("Developer Tools")
                        .font(.title.weight(.bold))
                        .foregroundColor(.frostWhite)
                }
                
                Text("Clean up development caches and storage")
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
        }
        .padding(24)
    }
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            TabButton(title: "Homebrew", icon: "shippingbox", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            TabButton(title: "Node.js", icon: "cube.box", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            TabButton(title: "Docker", icon: "cube.transparent", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            TabButton(title: "Git Repos", icon: "arrow.triangle.branch", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color.deepSpaceBlue.opacity(0.3))
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .frostWhite : .slateGray)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.emeraldGreen.opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Homebrew Tab

struct HomebrewTabView: View {
    @StateObject private var viewModel = HomebrewViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !viewModel.result.isInstalled {
                    notInstalledView(name: "Homebrew", installCmd: "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
                } else if viewModel.isScanning {
                    scanningView
                } else {
                    cacheCard
                    outdatedCard
                }
            }
            .padding(24)
        }
        .onAppear { Task { await viewModel.scan() } }
    }
    
    private var scanningView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(viewModel.statusText)
                .foregroundColor(.slateGray)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var cacheCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "archivebox.fill")
                        .foregroundColor(.orange)
                    Text("Homebrew Cache")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                    Spacer()
                    Text(viewModel.result.formattedCacheSize)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.emeraldGreen)
                }
                
                if viewModel.result.cacheSize > 0 {
                    Button {
                        Task { await viewModel.cleanCache() }
                    } label: {
                        Label("Clean Cache", systemImage: "trash")
                            .font(.subheadline)
                            .foregroundColor(.frostWhite)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Cache is clean")
                        .font(.caption)
                        .foregroundColor(.slateGray)
                }
            }
        }
    }
    
    private var outdatedCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.arrow.circlepath")
                        .foregroundColor(.yellow)
                    Text("Outdated Packages")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                    Spacer()
                    Text("\(viewModel.result.outdatedPackages.count)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(viewModel.result.outdatedPackages.isEmpty ? .emeraldGreen : .orange)
                }
                
                if !viewModel.result.outdatedPackages.isEmpty {
                    Text(viewModel.result.outdatedPackages.prefix(5).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.slateGray)
                        .lineLimit(2)
                } else {
                    Text("All packages up to date")
                        .font(.caption)
                        .foregroundColor(.slateGray)
                }
            }
        }
    }
}

// MARK: - Node.js Tab

struct NodeTabView: View {
    @StateObject private var viewModel = NodeViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isScanning {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text(viewModel.statusText)
                            .foregroundColor(.slateGray)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    // Caches
                    cachesCard
                    
                    // node_modules
                    nodeModulesCard
                }
            }
            .padding(24)
        }
        .onAppear { Task { await viewModel.scan() } }
    }
    
    private var cachesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "cube.box.fill")
                        .foregroundColor(.green)
                    Text("Package Manager Caches")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                    Spacer()
                    Text(viewModel.cacheResult.formattedTotalSize)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.emeraldGreen)
                }
                
                ForEach(viewModel.cacheResult.caches) { cache in
                    HStack {
                        Text(cache.name)
                            .font(.subheadline)
                            .foregroundColor(.slateGray)
                        Spacer()
                        Text(cache.formattedSize)
                            .font(.subheadline)
                            .foregroundColor(.frostWhite)
                    }
                }
                
                if viewModel.cacheResult.totalSize > 0 {
                    Button {
                        Task { await viewModel.cleanCaches() }
                    } label: {
                        Label("Clean All Caches", systemImage: "trash")
                            .font(.subheadline)
                            .foregroundColor(.frostWhite)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var nodeModulesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                    Text("node_modules Folders")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                    Spacer()
                    Text("\(viewModel.nodeModules.count) found")
                        .font(.subheadline)
                        .foregroundColor(.slateGray)
                }
                
                ForEach(viewModel.nodeModules.prefix(10)) { item in
                    HStack {
                        Text(item.projectName)
                            .font(.subheadline)
                            .foregroundColor(.frostWhite)
                        Spacer()
                        Text(item.formattedSize)
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
                
                if viewModel.nodeModules.count > 10 {
                    Text("... and \(viewModel.nodeModules.count - 10) more")
                        .font(.caption)
                        .foregroundColor(.slateGray)
                }
            }
        }
    }
}

// MARK: - Docker Tab

struct DockerTabView: View {
    @StateObject private var viewModel = DockerViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !viewModel.result.isInstalled {
                    notInstalledView(name: "Docker", installCmd: "brew install --cask docker")
                } else if !viewModel.result.isRunning {
                    VStack(spacing: 16) {
                        Image(systemName: "stop.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Docker is not running")
                            .font(.headline)
                            .foregroundColor(.frostWhite)
                        Text("Start Docker Desktop to scan")
                            .font(.subheadline)
                            .foregroundColor(.slateGray)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.isScanning {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text(viewModel.statusText)
                            .foregroundColor(.slateGray)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    diskUsageCard
                    imagesCard
                    containersCard
                }
            }
            .padding(24)
        }
        .onAppear { Task { await viewModel.scan() } }
    }
    
    private var diskUsageCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundColor(.blue)
                    Text("Docker Disk Usage")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                    Spacer()
                    
                    Button {
                        Task { await viewModel.prune() }
                    } label: {
                        Label("Prune All", systemImage: "trash")
                            .font(.caption)
                            .foregroundColor(.frostWhite)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                
                HStack(spacing: 24) {
                    StatBox(label: "Images", value: viewModel.result.diskUsage.imagesSize)
                    StatBox(label: "Containers", value: viewModel.result.diskUsage.containersSize)
                    StatBox(label: "Volumes", value: viewModel.result.diskUsage.volumesSize)
                    StatBox(label: "Reclaimable", value: viewModel.result.diskUsage.reclaimable)
                }
            }
        }
    }
    
    private var imagesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "photo.stack")
                        .foregroundColor(.purple)
                    Text("Images (\(viewModel.result.images.count))")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                }
                
                ForEach(viewModel.result.images.prefix(5)) { image in
                    HStack {
                        Text(image.fullName)
                            .font(.subheadline)
                            .foregroundColor(.frostWhite)
                            .lineLimit(1)
                        Spacer()
                        Text(image.size)
                            .font(.subheadline)
                            .foregroundColor(.slateGray)
                    }
                }
            }
        }
    }
    
    private var containersCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "shippingbox")
                        .foregroundColor(.cyan)
                    Text("Containers (\(viewModel.result.containers.count))")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                }
                
                ForEach(viewModel.result.containers.prefix(5)) { container in
                    HStack {
                        Circle()
                            .fill(container.isRunning ? Color.green : Color.slateGray)
                            .frame(width: 8, height: 8)
                        Text(container.name)
                            .font(.subheadline)
                            .foregroundColor(.frostWhite)
                        Spacer()
                        Text(container.status)
                            .font(.caption)
                            .foregroundColor(.slateGray)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

struct StatBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(.frostWhite)
            Text(label)
                .font(.caption)
                .foregroundColor(.slateGray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Git Tab

struct GitTabView: View {
    @StateObject private var viewModel = GitViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isScanning {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text(viewModel.statusText)
                            .foregroundColor(.slateGray)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    summaryCard
                    reposList
                }
            }
            .padding(24)
        }
        .onAppear { Task { await viewModel.scan() } }
    }
    
    private var summaryCard: some View {
        GlassCard {
            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundColor(.orange)
                Text("Git Repositories")
                    .font(.headline)
                    .foregroundColor(.frostWhite)
                Spacer()
                Text("\(viewModel.repos.count) found")
                    .foregroundColor(.slateGray)
                Text(viewModel.formattedTotalSize)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.emeraldGreen)
            }
        }
    }
    
    private var reposList: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.repos.prefix(20)) { repo in
                GlassCard(padding: 12) {
                    HStack {
                        Image(systemName: repo.isGitHub ? "link.circle.fill" : "folder.fill")
                            .foregroundColor(repo.isGitHub ? .white : .blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(repo.name)
                                .font(.subheadline)
                                .foregroundColor(.frostWhite)
                            
                            HStack(spacing: 8) {
                                Text(repo.currentBranch)
                                    .font(.caption)
                                    .foregroundColor(.emeraldGreen)
                                
                                Text("•")
                                    .foregroundColor(.slateGray)
                                
                                Text(repo.formattedLastCommit)
                                    .font(.caption)
                                    .foregroundColor(.slateGray)
                            }
                        }
                        
                        Spacer()
                        
                        Text(repo.formattedGitSize)
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views

func notInstalledView(name: String, installCmd: String) -> some View {
    VStack(spacing: 16) {
        Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 40))
            .foregroundColor(.orange)
        Text("\(name) Not Installed")
            .font(.headline)
            .foregroundColor(.frostWhite)
        Text("Install with:")
            .font(.subheadline)
            .foregroundColor(.slateGray)
        Text(installCmd)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.emeraldGreen)
            .padding(8)
            .background(Color.deepSpaceBlue)
            .cornerRadius(8)
    }
    .frame(maxWidth: .infinity, minHeight: 200)
}

// MARK: - ViewModels

@MainActor
class HomebrewViewModel: ObservableObject {
    @Published var result = HomebrewScanResult(isInstalled: false, cacheSize: 0, cacheItems: [], outdatedPackages: [])
    @Published var isScanning = false
    @Published var statusText = ""
    
    private let agent = HomebrewAgent()
    
    func scan() async {
        isScanning = true
        result = await agent.scan { [weak self] _, status in
            Task { @MainActor in self?.statusText = status }
        }
        isScanning = false
    }
    
    func cleanCache() async {
        _ = await agent.cleanCache()
        await scan()
    }
}

@MainActor
class NodeViewModel: ObservableObject {
    @Published var cacheResult = NodeCacheScanResult()
    @Published var nodeModules: [NodeModulesItem] = []
    @Published var isScanning = false
    @Published var statusText = ""
    
    private let agent = NodeAgent()
    
    func scan() async {
        isScanning = true
        cacheResult = await agent.scanCaches { [weak self] _, status in
            Task { @MainActor in self?.statusText = status }
        }
        nodeModules = await agent.findNodeModules { [weak self] _, status in
            Task { @MainActor in self?.statusText = status }
        }
        isScanning = false
    }
    
    func cleanCaches() async {
        _ = await agent.cleanCaches(cacheResult.caches)
        await scan()
    }
}

@MainActor
class DockerViewModel: ObservableObject {
    @Published var result = DockerScanResult(isInstalled: false, isRunning: false)
    @Published var isScanning = false
    @Published var statusText = ""
    
    private let agent = DockerAgent()
    
    func scan() async {
        isScanning = true
        result = await agent.scan { [weak self] _, status in
            Task { @MainActor in self?.statusText = status }
        }
        isScanning = false
    }
    
    func prune() async {
        _ = await agent.prune(includeVolumes: false)
        await scan()
    }
}

@MainActor
class GitViewModel: ObservableObject {
    @Published var repos: [GitRepository] = []
    @Published var isScanning = false
    @Published var statusText = ""
    
    private let agent = GitAgent()
    
    var formattedTotalSize: String {
        let total = repos.reduce(0) { $0 + $1.gitSize }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
    
    func scan() async {
        isScanning = true
        repos = await agent.findRepositories { [weak self] _, status in
            Task { @MainActor in self?.statusText = status }
        }
        isScanning = false
    }
}

#Preview {
    DeveloperToolsView()
        .frame(width: 800, height: 600)
        .background(Color.backgroundGradient)
}
