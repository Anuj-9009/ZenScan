import SwiftUI
import UniformTypeIdentifiers

/// Secure File Shredder view
struct ShredderView: View {
    @StateObject private var viewModel = ShredderViewModel()
    @State private var isDropTargeted = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .background(Color.slateGray.opacity(0.3))
            
            if viewModel.isShredding {
                shreddingView
            } else {
                dropZone
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "scissors")
                        .foregroundColor(.red)
                    Text("Secure Shredder")
                        .font(.title.weight(.bold))
                        .foregroundColor(.frostWhite)
                }
                
                Text("Permanently destroy files with multi-pass overwriting")
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
            
            // Pass selector
            HStack {
                Text("Security:")
                    .font(.caption)
                    .foregroundColor(.slateGray)
                
                Picker("", selection: $viewModel.selectedPasses) {
                    Text("Quick (1 pass)").tag(1)
                    Text("Standard (3 passes)").tag(3)
                    Text("Secure (7 passes)").tag(7)
                }
                .frame(width: 150)
            }
        }
        .padding(24)
    }
    
    private var dropZone: some View {
        VStack(spacing: 24) {
            if viewModel.files.isEmpty {
                // Empty drop zone
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 60))
                        .foregroundColor(isDropTargeted ? .red : .slateGray)
                    
                    Text("Drop files here to shred")
                        .font(.headline)
                        .foregroundColor(.slateGray)
                    
                    Text("Files will be permanently destroyed")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                    
                    Button {
                        viewModel.selectFiles()
                    } label: {
                        Label("Choose Files", systemImage: "folder")
                            .font(.headline)
                            .foregroundColor(.frostWhite)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isDropTargeted ? Color.red : Color.slateGray.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [10])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isDropTargeted ? Color.red.opacity(0.1) : Color.clear)
                        )
                )
                .padding(24)
            } else {
                // File list
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.files, id: \.self) { url in
                            FileRow(url: url) {
                                viewModel.removeFile(url)
                            }
                        }
                    }
                    .padding(24)
                }
                
                // Shred button
                HStack {
                    Text("\(viewModel.files.count) files selected")
                        .foregroundColor(.slateGray)
                    
                    Spacer()
                    
                    Button {
                        viewModel.clearFiles()
                    } label: {
                        Text("Clear")
                            .foregroundColor(.slateGray)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        Task { await viewModel.shred() }
                    } label: {
                        Label("Shred Files", systemImage: "scissors")
                            .font(.headline)
                            .foregroundColor(.frostWhite)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            viewModel.addFile(url)
                        }
                    }
                }
            }
            return true
        }
    }
    
    private var shreddingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated shredder icon
            Image(systemName: "scissors")
                .font(.system(size: 60))
                .foregroundColor(.red)
                .rotationEffect(.degrees(viewModel.progress * 360))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: viewModel.progress)
            
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .frame(width: 300)
            
            Text(viewModel.statusText)
                .font(.headline)
                .foregroundColor(.slateGray)
            
            Spacer()
        }
    }
}

struct FileRow: View {
    let url: URL
    let onRemove: () -> Void
    
    var body: some View {
        GlassCard(padding: 12) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(url.lastPathComponent)
                        .font(.subheadline)
                        .foregroundColor(.frostWhite)
                    
                    Text(url.deletingLastPathComponent().path)
                        .font(.caption)
                        .foregroundColor(.slateGray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.slateGray)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// ViewModel for Shredder
@MainActor
class ShredderViewModel: ObservableObject {
    @Published var files: [URL] = []
    @Published var selectedPasses = 3
    @Published var isShredding = false
    @Published var progress: Double = 0
    @Published var statusText = ""
    
    private let agent = ShredderAgent()
    
    func addFile(_ url: URL) {
        if !files.contains(url) {
            files.append(url)
        }
    }
    
    func removeFile(_ url: URL) {
        files.removeAll { $0 == url }
    }
    
    func clearFiles() {
        files = []
    }
    
    func selectFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        
        if panel.runModal() == .OK {
            files.append(contentsOf: panel.urls)
        }
    }
    
    func shred() async {
        guard !files.isEmpty else { return }
        
        isShredding = true
        progress = 0
        
        do {
            try await agent.shredFiles(files, passes: selectedPasses) { [weak self] prog, status in
                Task { @MainActor in
                    self?.progress = prog
                    self?.statusText = status
                }
            }
            files = []
        } catch {
            statusText = "Error: \(error.localizedDescription)"
        }
        
        isShredding = false
    }
}

#Preview {
    ShredderView()
        .frame(width: 700, height: 600)
        .background(Color.backgroundGradient)
}
