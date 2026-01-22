import SwiftUI

/// Duplicate Files Detector view
struct DuplicateView: View {
    @StateObject private var viewModel = DuplicateViewModel()
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .background(Color.slateGray.opacity(0.3))
            
            if viewModel.isScanning {
                scanningView
            } else if viewModel.groups.isEmpty {
                emptyState
            } else {
                duplicatesList
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Duplicate Files")
                    .font(.title.weight(.bold))
                    .foregroundColor(.frostWhite)
                
                Text("Find and remove duplicate files")
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
            
            if !viewModel.groups.isEmpty {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.formattedWastedSpace)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.emeraldGreen)
                    
                    Text("Wasted space")
                        .font(.caption)
                        .foregroundColor(.slateGray)
                }
                
                Button {
                    viewModel.selectAllDuplicates()
                } label: {
                    Text("Select All Duplicates")
                        .font(.caption)
                        .foregroundColor(.emeraldGreen)
                }
                .buttonStyle(.plain)
                
                if viewModel.selectedFilesCount > 0 {
                    Button {
                        showConfirmation = true
                    } label: {
                        Label("Delete \(viewModel.selectedFilesCount)", systemImage: "trash.fill")
                            .font(.headline)
                            .foregroundColor(.frostWhite)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.accentGradient)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button {
                Task { await viewModel.scan() }
            } label: {
                Label("Scan", systemImage: "magnifyingglass")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundColor(.emeraldGreen)
        }
        .padding(24)
    }
    
    private var scanningView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressRing(progress: viewModel.scanProgress, lineWidth: 8, size: 120)
            Text(viewModel.statusText)
                .font(.headline)
                .foregroundColor(.slateGray)
            Spacer()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.on.doc")
                .font(.system(size: 60))
                .foregroundColor(.slateGray)
            
            Text("Scan to find duplicate files")
                .font(.headline)
                .foregroundColor(.slateGray)
            
            Button {
                Task { await viewModel.scan() }
            } label: {
                Text("Start Scan")
                    .font(.headline)
                    .foregroundColor(.frostWhite)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.accentGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
    
    private var duplicatesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.groups.enumerated()), id: \.element.id) { index, group in
                    DuplicateGroupCard(
                        group: group,
                        onToggleFile: { file in
                            viewModel.toggleSelection(for: file, in: index)
                        }
                    )
                }
            }
            .padding(24)
        }
        .alert("Move to Trash?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Move to Trash", role: .destructive) {
                Task { _ = await viewModel.deleteSelected() }
            }
        } message: {
            Text("This will move \(viewModel.selectedFilesCount) duplicate files (\(viewModel.formattedSelectedSize)) to Trash. Original files will be kept.")
        }
    }
}

/// Card for a duplicate group
struct DuplicateGroupCard: View {
    let group: DuplicateGroup
    let onToggleFile: (DuplicateFile) -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        GlassCard(padding: 0) {
            VStack(spacing: 0) {
                // Header
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.title2)
                            .foregroundColor(.emeraldGreen)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(group.files.count) identical files")
                                .font(.headline)
                                .foregroundColor(.frostWhite)
                            
                            Text("Each file: \(group.formattedSize)")
                                .font(.caption)
                                .foregroundColor(.slateGray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(group.formattedWastedSpace)
                                .font(.headline)
                                .foregroundColor(.emeraldGreen)
                            
                            Text("wasted")
                                .font(.caption)
                                .foregroundColor(.slateGray)
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.slateGray)
                            .padding(.leading, 8)
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)
                
                if isExpanded {
                    Divider()
                        .background(Color.slateGray.opacity(0.2))
                    
                    VStack(spacing: 0) {
                        ForEach(group.files) { file in
                            DuplicateFileRow(file: file) {
                                onToggleFile(file)
                            }
                            
                            if file.id != group.files.last?.id {
                                Divider()
                                    .background(Color.slateGray.opacity(0.1))
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Row for a duplicate file
struct DuplicateFileRow: View {
    let file: DuplicateFile
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                if file.isOriginal {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.emeraldGreen)
                        .font(.title3)
                } else {
                    Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(file.isSelected ? .emeraldGreen : .slateGray)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(file.name)
                            .font(.subheadline)
                            .foregroundColor(.frostWhite)
                            .lineLimit(1)
                        
                        if file.isOriginal {
                            Text("ORIGINAL")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.emeraldGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.emeraldGreen.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(file.parentPath)
                        .font(.caption2)
                        .foregroundColor(.slateGray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if let date = file.modificationDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.slateGray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(file.isOriginal)
        .opacity(file.isOriginal ? 0.7 : 1.0)
    }
}

#Preview {
    DuplicateView()
        .frame(width: 700, height: 600)
        .background(Color.backgroundGradient)
}
