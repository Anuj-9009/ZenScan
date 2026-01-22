import SwiftUI

/// Large Files Finder view
struct LargeFilesView: View {
    @StateObject private var viewModel = LargeFilesViewModel()
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .background(Color.slateGray.opacity(0.3))
            
            if viewModel.isScanning {
                scanningView
            } else if viewModel.files.isEmpty {
                emptyState
            } else {
                filesList
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Large Files")
                    .font(.title.weight(.bold))
                    .foregroundColor(.frostWhite)
                
                Text("Find and remove large files taking up space")
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
            
            // Threshold picker
            Picker("Size", selection: $viewModel.selectedThreshold) {
                ForEach(FileSizeThreshold.allCases) { threshold in
                    Text(threshold.displayName).tag(threshold)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            
            if !viewModel.files.isEmpty {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.formattedSelectedSize)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.emeraldGreen)
                    
                    Text("\(viewModel.selectedFiles.count) selected")
                        .font(.caption)
                        .foregroundColor(.slateGray)
                }
                
                Button {
                    showConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentGradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.selectedFiles.isEmpty)
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
            
            Image(systemName: "doc.badge.gearshape")
                .font(.system(size: 60))
                .foregroundColor(.slateGray)
            
            Text("Scan to find large files")
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
    
    private var filesList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                // Stats bar
                HStack {
                    Text("\(viewModel.files.count) files found")
                        .font(.subheadline)
                        .foregroundColor(.slateGray)
                    
                    Spacer()
                    
                    Text("Total: \(viewModel.formattedTotalSize)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.emeraldGreen)
                    
                    Button {
                        viewModel.sortBySize.toggle()
                        viewModel.applySorting()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.sortBySize ? "arrow.down" : "textformat.abc")
                            Text(viewModel.sortBySize ? "By Size" : "By Name")
                        }
                        .font(.caption)
                        .foregroundColor(.slateGray)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                
                ForEach(viewModel.files) { file in
                    LargeFileRow(file: file) {
                        viewModel.toggleSelection(for: file)
                    }
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
            Text("This will move \(viewModel.selectedFiles.count) files (\(viewModel.formattedSelectedSize)) to Trash.")
        }
    }
}

/// Large file row item
struct LargeFileRow: View {
    let file: LargeFile
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            GlassCard(padding: 12) {
                HStack(spacing: 16) {
                    Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(file.isSelected ? .emeraldGreen : .slateGray)
                        .font(.title2)
                    
                    Image(systemName: file.icon)
                        .font(.title2)
                        .foregroundColor(.emeraldGreen)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.name)
                            .font(.headline)
                            .foregroundColor(.frostWhite)
                            .lineLimit(1)
                        
                        Text(file.parentPath)
                            .font(.caption)
                            .foregroundColor(.slateGray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(file.formattedSize)
                            .font(.headline)
                            .foregroundColor(.emeraldGreen)
                        
                        if let date = file.modificationDate {
                            Text(date, style: .date)
                                .font(.caption2)
                                .foregroundColor(.slateGray)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LargeFilesView()
        .frame(width: 700, height: 600)
        .background(Color.backgroundGradient)
}
