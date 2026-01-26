import Foundation

/// Agent for managing Time Machine snapshots
actor TimeMachineAgent {
    private let fileManager = FileManager.default
    
    /// Check if Time Machine is configured
    var isConfigured: Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
        process.arguments = ["destinationinfo"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// Get local snapshots
    func getLocalSnapshots(progress: @escaping (Double, String) -> Void) async -> [TimeMachineSnapshot] {
        await MainActor.run { progress(0, "Checking Time Machine...") }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var snapshots: [TimeMachineSnapshot] = []
                
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
                process.arguments = ["listlocalsnapshots", "/"]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8) {
                        let lines = output.components(separatedBy: .newlines)
                        
                        for line in lines {
                            if line.contains("com.apple.TimeMachine") {
                                // Parse snapshot name like: com.apple.TimeMachine.2024-01-15-120000
                                let components = line.components(separatedBy: ".")
                                if let dateStr = components.last {
                                    let snapshot = TimeMachineSnapshot(
                                        name: line.trimmingCharacters(in: .whitespaces),
                                        dateString: dateStr
                                    )
                                    snapshots.append(snapshot)
                                }
                            }
                        }
                    }
                } catch {
                    // tmutil failed
                }
                
                DispatchQueue.main.async { progress(1.0, "Found \(snapshots.count) snapshots") }
                continuation.resume(returning: snapshots.sorted { $0.dateString > $1.dateString })
            }
        }
    }
    
    /// Delete a local snapshot (requires sudo)
    func deleteSnapshot(_ snapshot: TimeMachineSnapshot) async -> Bool {
        // Note: This requires administrator privileges
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
                process.arguments = ["deletelocalsnapshots", snapshot.dateString]
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
    
    /// Get Time Machine backup status
    func getBackupStatus() async -> TimeMachineStatus {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var status = TimeMachineStatus()
                
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
                process.arguments = ["status"]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8) {
                        status.isRunning = output.contains("Running = 1")
                        
                        // Parse progress if running
                        if let percentMatch = output.range(of: "Percent = ([0-9.]+)", options: .regularExpression) {
                            let percentStr = String(output[percentMatch])
                            if let value = Double(percentStr.replacingOccurrences(of: "Percent = ", with: "")) {
                                status.progress = value
                            }
                        }
                    }
                } catch {
                    // Failed to get status
                }
                
                continuation.resume(returning: status)
            }
        }
    }
}

/// Time Machine snapshot
struct TimeMachineSnapshot: Identifiable {
    let id = UUID()
    let name: String
    let dateString: String
    var isSelected: Bool = false
    
    var formattedDate: String {
        // Parse date string like "2024-01-15-120000"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

/// Time Machine backup status
struct TimeMachineStatus {
    var isRunning: Bool = false
    var progress: Double = 0
}
