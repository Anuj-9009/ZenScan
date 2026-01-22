import Foundation

/// ViewModel for Large Files Finder module
@MainActor
class LargeFilesViewModel: ObservableObject {
    @Published var files: [LargeFile] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var statusText = ""
    @Published var selectedThreshold: FileSizeThreshold = .mb100
    @Published var sortBySize = true
    
    private let agent = LargeFilesAgent()
    
    var selectedFiles: [LargeFile] {
        files.filter { $0.isSelected }
    }
    
    var totalSelectedSize: Int64 {
        selectedFiles.reduce(0) { $0 + $1.size }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file)
    }
    
    var totalSize: Int64 {
        files.reduce(0) { $0 + $1.size }
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    func scan() async {
        isScanning = true
        scanProgress = 0
        statusText = "Scanning for large files..."
        
        files = await agent.scanForLargeFiles(
            threshold: selectedThreshold.rawValue
        ) { [weak self] progress, status in
            Task { @MainActor in
                self?.scanProgress = progress
                self?.statusText = status
            }
        }
        
        applySorting()
        isScanning = false
    }
    
    func applySorting() {
        if sortBySize {
            files.sort { $0.size > $1.size }
        } else {
            files.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }
    
    func toggleSelection(for file: LargeFile) {
        if let index = files.firstIndex(where: { $0.id == file.id }) {
            files[index].isSelected.toggle()
        }
    }
    
    func selectAll() {
        for i in files.indices {
            files[i].isSelected = true
        }
    }
    
    func deselectAll() {
        for i in files.indices {
            files[i].isSelected = false
        }
    }
    
    func deleteSelected() async -> (deleted: Int, failed: Int) {
        let result = await agent.deleteFiles(selectedFiles)
        await scan()
        return result
    }
}
