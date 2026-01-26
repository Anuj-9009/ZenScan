import Foundation
import Combine

/// ViewModel for duplicate file detection and management
@MainActor
class DuplicateViewModel: ObservableObject {
    @Published var groups: [DuplicateGroup] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var statusText = ""
    
    private let agent = DuplicateAgent()
    
    /// Total wasted space from duplicates
    var wastedSpace: Int64 {
        groups.reduce(0) { $0 + $1.wastedSpace }
    }
    
    /// Formatted wasted space
    var formattedWastedSpace: String {
        ByteCountFormatter.string(fromByteCount: wastedSpace, countStyle: .file)
    }
    
    /// Number of selected files
    var selectedFilesCount: Int {
        groups.flatMap { $0.files.filter { $0.isSelected && !$0.isOriginal } }.count
    }
    
    /// Size of selected files
    var selectedSize: Int64 {
        groups.flatMap { $0.files.filter { $0.isSelected && !$0.isOriginal } }
            .reduce(0) { $0 + $1.size }
    }
    
    /// Formatted selected size
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }
    
    /// Scan for duplicates
    func scan() async {
        isScanning = true
        scanProgress = 0
        statusText = "Preparing scan..."
        
        groups = await agent.scanForDuplicates { [weak self] progress, status in
            Task { @MainActor in
                self?.scanProgress = progress
                self?.statusText = status
            }
        }
        
        isScanning = false
    }
    
    /// Toggle file selection
    func toggleSelection(for file: DuplicateFile, in groupIndex: Int) {
        guard groupIndex < groups.count,
              !file.isOriginal else { return }
        
        if let fileIndex = groups[groupIndex].files.firstIndex(where: { $0.id == file.id }) {
            groups[groupIndex].files[fileIndex].isSelected.toggle()
        }
    }
    
    /// Select all duplicates (not originals)
    func selectAllDuplicates() {
        for groupIndex in groups.indices {
            for fileIndex in groups[groupIndex].files.indices {
                if !groups[groupIndex].files[fileIndex].isOriginal {
                    groups[groupIndex].files[fileIndex].isSelected = true
                }
            }
        }
    }
    
    /// Deselect all
    func deselectAll() {
        for groupIndex in groups.indices {
            for fileIndex in groups[groupIndex].files.indices {
                groups[groupIndex].files[fileIndex].isSelected = false
            }
        }
    }
    
    /// Delete selected files
    func deleteSelected() async -> (deleted: Int, failed: Int) {
        let selectedFiles = groups.flatMap { $0.files.filter { $0.isSelected && !$0.isOriginal } }
        
        guard !selectedFiles.isEmpty else { return (0, 0) }
        
        let result = await agent.deleteFiles(selectedFiles)
        
        // Refresh after deletion
        await scan()
        
        return result
    }
}
