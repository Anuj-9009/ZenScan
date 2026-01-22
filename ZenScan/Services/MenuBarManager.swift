import SwiftUI
import AppKit

/// Menu bar manager for ZenScan
class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    @Published var isVisible = false
    
    init() {
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "ZenScan")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarView())
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
            isVisible = false
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            isVisible = true
        }
    }
    
    func show() {
        if let button = statusItem?.button {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            isVisible = true
        }
    }
    
    func hide() {
        popover?.performClose(nil)
        isVisible = false
    }
}

/// Menu bar popover view
struct MenuBarView: View {
    @StateObject private var systemMonitor = SystemMonitor()
    @State private var lastScanDate: Date? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.emeraldGreen)
                Text("ZenScan")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color.deepSpaceBlue)
            
            Divider()
            
            // System stats
            VStack(spacing: 12) {
                // Memory usage
                StatRow(
                    icon: "memorychip",
                    title: "Memory",
                    value: systemMonitor.formattedMemoryUsage,
                    progress: systemMonitor.memoryUsagePercent
                )
                
                // Disk usage
                StatRow(
                    icon: "internaldrive",
                    title: "Disk",
                    value: systemMonitor.formattedDiskUsage,
                    progress: systemMonitor.diskUsagePercent
                )
                
                // CPU usage
                StatRow(
                    icon: "cpu",
                    title: "CPU",
                    value: "\(Int(systemMonitor.cpuUsage))%",
                    progress: systemMonitor.cpuUsage / 100
                )
            }
            .padding()
            
            Divider()
            
            // Quick actions
            VStack(spacing: 8) {
                QuickActionButton(icon: "magnifyingglass", title: "Quick Scan") {
                    NSApp.activate(ignoringOtherApps: true)
                    // Trigger scan in main app
                }
                
                QuickActionButton(icon: "trash", title: "Clean Junk") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                
                QuickActionButton(icon: "arrow.clockwise", title: "Refresh Stats") {
                    Task {
                        await systemMonitor.refresh()
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Footer
            HStack {
                if let date = lastScanDate {
                    Text("Last scan: \(date, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("No recent scan")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button("Open ZenScan") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                .font(.caption)
            }
            .padding()
        }
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            Task {
                await systemMonitor.refresh()
            }
        }
    }
}

/// Stat row for menu bar
struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let progress: Double
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.emeraldGreen)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
            
            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                    
                    Capsule()
                        .fill(progressColor)
                        .frame(width: geo.size.width * min(1, progress))
                }
            }
            .frame(width: 60, height: 6)
        }
    }
    
    var progressColor: Color {
        if progress > 0.9 {
            return .red
        } else if progress > 0.7 {
            return .orange
        } else {
            return .emeraldGreen
        }
    }
}

/// Quick action button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
