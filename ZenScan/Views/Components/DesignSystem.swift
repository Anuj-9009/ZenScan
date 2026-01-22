import SwiftUI

/// Custom design system colors for ZenScan
extension Color {
    /// Deep Space Blue - Primary background (#0B1426)
    static let deepSpaceBlue = Color(red: 0.043, green: 0.078, blue: 0.149)
    
    /// Frost White - Text and highlights (#F8FAFC)
    static let frostWhite = Color(red: 0.973, green: 0.98, blue: 0.988)
    
    /// Emerald Green - Success states (#10B981)
    static let emeraldGreen = Color(red: 0.063, green: 0.725, blue: 0.506)
    
    /// Slate Gray - Secondary text (#64748B)
    static let slateGray = Color(red: 0.392, green: 0.455, blue: 0.545)
    
    /// Accent gradient
    static let accentGradient = LinearGradient(
        colors: [emeraldGreen, emeraldGreen.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Background gradient
    static let backgroundGradient = LinearGradient(
        colors: [deepSpaceBlue, Color(red: 0.08, green: 0.12, blue: 0.22)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Glassmorphism card container
struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    
    init(padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

/// Size bubble visualization
struct SizeBubble: View {
    let size: Int64
    let maxSize: Int64
    var color: Color = .emeraldGreen
    
    private var relativeSize: CGFloat {
        let ratio = CGFloat(size) / CGFloat(max(maxSize, 1))
        return max(30, min(100, 30 + ratio * 70))
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: relativeSize, height: relativeSize)
            
            Circle()
                .fill(color.opacity(0.5))
                .frame(width: relativeSize * 0.7, height: relativeSize * 0.7)
            
            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                .font(.system(size: max(8, relativeSize / 6), weight: .medium, design: .rounded))
                .foregroundColor(.frostWhite)
        }
    }
}

/// Circular progress ring
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 100
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.slateGray.opacity(0.3), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.accentGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
        .frame(width: size, height: size)
    }
}

/// Large animated scan button
struct ScanButton: View {
    let isScanning: Bool
    let action: () -> Void
    
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow
                if !isScanning {
                    Circle()
                        .fill(Color.emeraldGreen.opacity(0.3))
                        .frame(width: 180, height: 180)
                        .scaleEffect(isPulsing ? 1.1 : 1.0)
                        .opacity(isPulsing ? 0.5 : 1.0)
                }
                
                // Main button
                Circle()
                    .fill(Color.accentGradient)
                    .frame(width: 150, height: 150)
                    .shadow(color: .emeraldGreen.opacity(0.5), radius: 20)
                
                // Content
                if isScanning {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.frostWhite)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.system(size: 40))
                        Text("Scan")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.frostWhite)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isScanning)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

/// Stat card for dashboard
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    var color: Color = .emeraldGreen
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.frostWhite)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.frostWhite)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.slateGray)
            }
        }
        .frame(minWidth: 150)
    }
}

#Preview {
    VStack(spacing: 20) {
        ScanButton(isScanning: false) {}
        
        HStack(spacing: 16) {
            StatCard(
                icon: "trash.circle.fill",
                title: "System Junk",
                value: "2.4 GB",
                subtitle: "Ready to clean"
            )
            
            StatCard(
                icon: "app.badge.checkmark",
                title: "Applications",
                value: "47",
                subtitle: "Installed apps"
            )
        }
        .padding()
    }
    .frame(width: 600, height: 500)
    .background(Color.backgroundGradient)
}
