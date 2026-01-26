import Foundation

/// Agent for Docker container, image, and volume management
actor DockerAgent {
    private let fileManager = FileManager.default
    
    /// Docker Desktop data path
    private var dockerDataPath: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Containers/com.docker.docker/Data")
    }
    
    /// Check if Docker is installed
    var isInstalled: Bool {
        fileManager.fileExists(atPath: "/usr/local/bin/docker") ||
        fileManager.fileExists(atPath: "/opt/homebrew/bin/docker") ||
        fileManager.fileExists(atPath: "/Applications/Docker.app")
    }
    
    /// Check if Docker daemon is running
    func isRunning() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
                process.arguments = ["info"]
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
    
    /// Scan Docker usage
    func scan(progress: @escaping (Double, String) -> Void) async -> DockerScanResult {
        await MainActor.run { progress(0, "Checking Docker installation...") }
        
        guard isInstalled else {
            return DockerScanResult(isInstalled: false, isRunning: false)
        }
        
        let running = await isRunning()
        if !running {
            return DockerScanResult(isInstalled: true, isRunning: false)
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result = DockerScanResult(isInstalled: true, isRunning: true)
                
                // Get images
                DispatchQueue.main.async { progress(0.25, "Listing Docker images...") }
                result.images = self.getDockerImages()
                
                // Get containers
                DispatchQueue.main.async { progress(0.5, "Listing Docker containers...") }
                result.containers = self.getDockerContainers()
                
                // Get volumes
                DispatchQueue.main.async { progress(0.75, "Listing Docker volumes...") }
                result.volumes = self.getDockerVolumes()
                
                // Get disk usage
                DispatchQueue.main.async { progress(0.9, "Calculating disk usage...") }
                result.diskUsage = self.getDockerDiskUsage()
                
                DispatchQueue.main.async { progress(1.0, "Scan complete") }
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Get Docker images
    private func getDockerImages() -> [DockerImage] {
        let output = runDockerCommand(["images", "--format", "{{.Repository}}|{{.Tag}}|{{.Size}}|{{.ID}}"])
        return output.components(separatedBy: .newlines).compactMap { line -> DockerImage? in
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 4 else { return nil }
            return DockerImage(
                id: parts[3],
                repository: parts[0],
                tag: parts[1],
                size: parts[2]
            )
        }
    }
    
    /// Get Docker containers
    private func getDockerContainers() -> [DockerContainer] {
        let output = runDockerCommand(["ps", "-a", "--format", "{{.Names}}|{{.Image}}|{{.Status}}|{{.ID}}"])
        return output.components(separatedBy: .newlines).compactMap { line -> DockerContainer? in
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 4 else { return nil }
            return DockerContainer(
                id: parts[3],
                name: parts[0],
                image: parts[1],
                status: parts[2]
            )
        }
    }
    
    /// Get Docker volumes
    private func getDockerVolumes() -> [DockerVolume] {
        let output = runDockerCommand(["volume", "ls", "--format", "{{.Name}}|{{.Driver}}"])
        return output.components(separatedBy: .newlines).compactMap { line -> DockerVolume? in
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 2 else { return nil }
            return DockerVolume(
                name: parts[0],
                driver: parts[1]
            )
        }
    }
    
    /// Get Docker disk usage
    private func getDockerDiskUsage() -> DockerDiskUsage {
        let output = runDockerCommand(["system", "df", "--format", "{{.Type}}|{{.Size}}|{{.Reclaimable}}"])
        var usage = DockerDiskUsage()
        
        for line in output.components(separatedBy: .newlines) {
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 3 else { continue }
            
            switch parts[0] {
            case "Images": usage.imagesSize = parts[1]
            case "Containers": usage.containersSize = parts[1]
            case "Local Volumes": usage.volumesSize = parts[1]
            case "Build Cache": usage.buildCacheSize = parts[1]
            default: break
            }
            
            usage.reclaimable = parts[2]
        }
        
        return usage
    }
    
    /// Run Docker command
    private func runDockerCommand(_ arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
    
    /// Prune unused Docker data
    func prune(includeVolumes: Bool = false) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var args = ["system", "prune", "-f"]
                if includeVolumes {
                    args.append("--volumes")
                }
                
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
                process.arguments = args
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
}

/// Docker scan result
struct DockerScanResult {
    var isInstalled: Bool
    var isRunning: Bool
    var images: [DockerImage] = []
    var containers: [DockerContainer] = []
    var volumes: [DockerVolume] = []
    var diskUsage: DockerDiskUsage = DockerDiskUsage()
}

/// Docker image
struct DockerImage: Identifiable {
    let id: String
    let repository: String
    let tag: String
    let size: String
    var isSelected: Bool = false
    
    var fullName: String {
        "\(repository):\(tag)"
    }
}

/// Docker container
struct DockerContainer: Identifiable {
    let id: String
    let name: String
    let image: String
    let status: String
    var isSelected: Bool = false
    
    var isRunning: Bool {
        status.lowercased().contains("up")
    }
}

/// Docker volume
struct DockerVolume: Identifiable {
    var id: String { name }
    let name: String
    let driver: String
    var isSelected: Bool = false
}

/// Docker disk usage
struct DockerDiskUsage {
    var imagesSize: String = "-"
    var containersSize: String = "-"
    var volumesSize: String = "-"
    var buildCacheSize: String = "-"
    var reclaimable: String = "-"
}
