import SwiftUI

/// Animated progress ring with smooth animations
struct AnimatedRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    let backgroundColor: Color
    let showLabel: Bool
    let labelFormat: String
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        color: Color = .emeraldGreen,
        backgroundColor: Color = Color.slateGray.opacity(0.2),
        showLabel: Bool = true,
        labelFormat: String = "%.0f%%"
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.color = color
        self.backgroundColor = backgroundColor
        self.showLabel = showLabel
        self.labelFormat = labelFormat
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.5), color]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * animatedProgress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Label
            if showLabel {
                Text(String(format: labelFormat, animatedProgress * 100))
                    .font(.system(size: lineWidth * 2, weight: .bold, design: .rounded))
                    .foregroundColor(.frostWhite)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

/// Stats card with animated number
struct AnimatedStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String?
    
    @State private var isAnimated = false
    
    init(title: String, value: String, icon: String, color: Color = .emeraldGreen, subtitle: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.subtitle = subtitle
    }
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                        .scaleEffect(isAnimated ? 1.0 : 0.5)
                    
                    Spacer()
                }
                
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.frostWhite)
                    .opacity(isAnimated ? 1 : 0)
                    .offset(y: isAnimated ? 0 : 10)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(color)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isAnimated = true
            }
        }
    }
}

/// Pulsing dot indicator
struct PulsingDot: View {
    let color: Color
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 2)
                    .scaleEffect(isPulsing ? 2 : 1)
                    .opacity(isPulsing ? 0 : 1)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}

/// Animated count-up text
struct AnimatedNumber: View {
    let value: Int64
    let format: (Int64) -> String
    
    @State private var displayValue: Int64 = 0
    
    var body: some View {
        Text(format(displayValue))
            .onAppear {
                animateValue()
            }
            .onChange(of: value) { _, _ in
                animateValue()
            }
    }
    
    private func animateValue() {
        let steps = 20
        let duration = 0.5
        let stepDuration = duration / Double(steps)
        let increment = (value - displayValue) / Int64(steps)
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                if i == steps - 1 {
                    displayValue = value
                } else {
                    displayValue += increment
                }
            }
        }
    }
}

/// System health gauge
struct HealthGauge: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.slateGray.opacity(0.2), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(value * 100))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.frostWhite)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.slateGray)
        }
    }
}

/// Live system monitor widget
struct LiveSystemWidget: View {
    @StateObject private var monitor = SystemMonitor()
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    PulsingDot(color: .emeraldGreen)
                    Text("Live System Stats")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                }
                
                HStack(spacing: 24) {
                    HealthGauge(label: "CPU", value: monitor.cpuUsage / 100.0, color: cpuColor)
                    HealthGauge(label: "Memory", value: monitor.memoryUsagePercent, color: memoryColor)
                    HealthGauge(label: "Disk", value: monitor.diskUsagePercent, color: diskColor)
                }
            }
        }
        .onAppear {
            monitor.startAutoRefresh(interval: 3.0)
        }
        .onDisappear {
            monitor.stopAutoRefresh()
        }
    }
    
    private var cpuColor: Color {
        let usage = monitor.cpuUsage / 100.0
        return usage > 0.8 ? .red : usage > 0.5 ? .orange : .emeraldGreen
    }
    
    private var memoryColor: Color {
        monitor.memoryUsagePercent > 0.8 ? .red : monitor.memoryUsagePercent > 0.5 ? .orange : .emeraldGreen
    }
    
    private var diskColor: Color {
        monitor.diskUsagePercent > 0.9 ? .red : monitor.diskUsagePercent > 0.7 ? .orange : .emeraldGreen
    }
}

#Preview {
    VStack(spacing: 20) {
        AnimatedRing(progress: 0.75, lineWidth: 16)
            .frame(width: 120, height: 120)
        
        HStack {
            AnimatedStatCard(title: "Junk Found", value: "2.4 GB", icon: "trash.fill", color: .orange)
            AnimatedStatCard(title: "Apps", value: "127", icon: "square.stack.3d.up.fill", color: .blue)
        }
        
        LiveSystemWidget()
    }
    .padding()
    .background(Color.backgroundGradient)
}
