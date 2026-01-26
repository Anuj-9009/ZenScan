import SwiftUI

/// Permissions audit view
struct PermissionsView: View {
    @StateObject private var viewModel = PermissionsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                
                if viewModel.isScanning {
                    scanningView
                } else if viewModel.categories.isEmpty {
                    emptyView
                } else {
                    permissionsGrid
                }
            }
            .padding(24)
        }
        .onAppear { Task { await viewModel.scan() } }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "hand.raised.circle.fill")
                        .foregroundColor(.emeraldGreen)
                    Text("Permissions Audit")
                        .font(.title.weight(.bold))
                        .foregroundColor(.frostWhite)
                }
                
                Text("Review which apps have access to sensitive data")
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
            
            Button {
                Task { await viewModel.scan() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.subheadline)
                    .foregroundColor(.frostWhite)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.emeraldGreen)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
    
    private var scanningView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text(viewModel.statusText)
                .foregroundColor(.slateGray)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(.emeraldGreen)
            Text("No Permission Issues Found")
                .font(.headline)
                .foregroundColor(.frostWhite)
            Text("Your apps appear to have appropriate permissions")
                .font(.subheadline)
                .foregroundColor(.slateGray)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    private var permissionsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(viewModel.categories) { category in
                permissionCard(for: category)
            }
        }
    }
    
    private func permissionCard(for category: PermissionCategory) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(.emeraldGreen)
                    
                    Text(category.type.rawValue)
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                    
                    Spacer()
                    
                    Text("\(category.apps.count) apps")
                        .font(.caption)
                        .foregroundColor(.slateGray)
                }
                
                Divider()
                    .background(Color.slateGray.opacity(0.3))
                
                ForEach(category.apps) { app in
                    HStack {
                        Image(systemName: "app.fill")
                            .foregroundColor(.blue)
                        Text(app.name)
                            .font(.subheadline)
                            .foregroundColor(.frostWhite)
                        Spacer()
                    }
                }
                
                Button {
                    Task { await viewModel.openSettings(for: category.type) }
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("Manage in Settings")
                    }
                    .font(.caption)
                    .foregroundColor(.emeraldGreen)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

@MainActor
class PermissionsViewModel: ObservableObject {
    @Published var categories: [PermissionCategory] = []
    @Published var isScanning = false
    @Published var statusText = ""
    
    private let agent = PermissionsAgent()
    
    func scan() async {
        isScanning = true
        categories = await agent.scanPermissions { [weak self] _, status in
            Task { @MainActor in self?.statusText = status }
        }
        isScanning = false
    }
    
    func openSettings(for type: PermissionsAgent.PermissionType) async {
        await agent.openPermissionSettings(for: type)
    }
}

#Preview {
    PermissionsView()
        .frame(width: 800, height: 600)
        .background(Color.backgroundGradient)
}
