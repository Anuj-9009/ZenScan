import Foundation

/// ViewModel for Duplicate Files Detector
@MainActor
class DuplicateViewModel: ObservableObject {
    @Published var groups: [DuplicateGroup] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var statusText = ""
    
    private let agent = DuplicateAgent()
    
    var totalWastedSpace: Int64 {
        groups.reduce(0) { $0 + $1.wastedSpace }
    }
    
    var formattedWastedSpace: String {
        ByteCountFormatter.string(fromByteCount: totalWastedSpace, countStyle: .file)
    }
    
    var selectedFilesCount: Int {
        groups.flatMap { $0.files.filter { $0.isSelected } }.count
    }
    
    var selectedSize: Int64 {
        groups.flatMap { $0.files.filter { $0.isSelected } }.reduce(0) { $0 + $1.size }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }
    
    func scan() async {
        isScanning = true
        scanProgress = 0
        statusText = "Scanning for duplicates..."
        
        groups = await agent.scanForDuplicates { [weak self] progress, status in
            Task { @MainActor in
                self?.scanProgress = progress
                self?.statusText = status
            }
        }
        
        isScanning = false
    }
    
    func toggleSelection(for file: DuplicateFile, in groupIndex: Int) {
        if let fileIndex = groups[groupIndex].files.firstIndex(where: { $0.id == file.id }) {
            // Don't allow selecting the original
            if !groups[groupIndex].files[fileIndex].isOriginal {
                groups[groupIndex].files[fileIndex].isSelected.toggle()
            }
        }
    }
    
    func selectAllDuplicates() {
        for groupIndex in groups.indices {
            for fileIndex in groups[groupIndex].files.indices {
                if !groups[groupIndex].files[fileIndex].isOriginal {
                    groups[groupIndex].files[fileIndex].isSelected = true
                }
            }
        }
    }
    
    func deselectAll() {
        for groupIndex in groups.indices {
            for fileIndex in groups[groupIndex].files.indices {
                groups[groupIndex].files[fileIndex].isSelected = false
            }
        }
    }
    
    func deleteSelected() async -> (deleted: Int, failed: Int) {
        let selectedFiles = groups.flatMap { $0.files.filter { $0.isSelected } }
        let result = await agent.deleteFiles(selectedFiles)
        await scan()
        return result
    }
}
