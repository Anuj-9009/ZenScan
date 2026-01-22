import SwiftUI

/// Battery Health view
struct BatteryHealthView: View {
    @StateObject private var batteryMonitor = BatteryMonitor()
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .background(Color.slateGray.opacity(0.3))
            
            if !batteryMonitor.batteryInfo.isPresent {
                noBatteryView
            } else {
                batteryContent
            }
        }
        .onAppear {
            batteryMonitor.refresh()
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "battery.100")
                        .foregroundColor(.emeraldGreen)
                    Text("Battery Health")
                        .font(.title.weight(.bold))
                        .foregroundColor(.frostWhite)
                }
                
                Text("Monitor your MacBook's battery condition")
                    .font(.subheadline)
                    .foregroundColor(.slateGray)
            }
            
            Spacer()
            
            Button {
                batteryMonitor.refresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundColor(.emeraldGreen)
        }
        .padding(24)
    }
    
    private var noBatteryView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bolt.slash")
                .font(.system(size: 60))
                .foregroundColor(.slateGray)
            
            Text("No Battery Detected")
                .font(.headline)
                .foregroundColor(.slateGray)
            
            Text("This feature is for MacBooks only")
                .font(.subheadline)
                .foregroundColor(.slateGray.opacity(0.7))
            
            Spacer()
        }
    }
    
    private var batteryContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Main battery status
                batteryStatusCard
                
                // Health details
                healthDetailsCard
                
                // Additional info
                additionalInfoCard
            }
            .padding(24)
        }
    }
    
    private var batteryStatusCard: some View {
        GlassCard {
            HStack(spacing: 40) {
                // Battery visual
                ZStack {
                    // Battery outline
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.slateGray.opacity(0.5), lineWidth: 3)
                        .frame(width: 120, height: 60)
                    
                    // Battery fill
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(chargeColor)
                            .frame(
                                width: CGFloat(batteryMonitor.batteryInfo.chargePercent) * 1.1,
                                height: 50
                            )
                            .padding(.leading, 5)
                        Spacer()
                    }
                    .frame(width: 115, height: 60)
                    
                    // Charge percentage
                    Text("\(batteryMonitor.batteryInfo.chargePercent)%")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.frostWhite)
                    
                    // Battery tip
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.slateGray.opacity(0.5))
                        .frame(width: 6, height: 20)
                        .offset(x: 63)
                    
                    // Charging indicator
                    if batteryMonitor.batteryInfo.isCharging {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .offset(y: 35)
                    }
                }
                
                // Status info
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: batteryMonitor.batteryInfo.isPluggedIn ? "powerplug.fill" : "battery.100")
                            .foregroundColor(.emeraldGreen)
                        
                        Text(batteryMonitor.batteryInfo.isPluggedIn ? "Plugged In" : "On Battery")
                            .font(.headline)
                            .foregroundColor(.frostWhite)
                    }
                    
                    if batteryMonitor.batteryInfo.isCharging {
                        Text("Time to full: \(batteryMonitor.batteryInfo.formattedTimeToFull)")
                            .font(.subheadline)
                            .foregroundColor(.slateGray)
                    } else if !batteryMonitor.batteryInfo.isPluggedIn {
                        Text("Time remaining: \(batteryMonitor.batteryInfo.formattedTimeRemaining)")
                            .font(.subheadline)
                            .foregroundColor(.slateGray)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var chargeColor: Color {
        let percent = batteryMonitor.batteryInfo.chargePercent
        if percent <= 20 {
            return .red
        } else if percent <= 40 {
            return .orange
        } else {
            return .emeraldGreen
        }
    }
    
    private var healthDetailsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Battery Health")
                        .font(.headline)
                        .foregroundColor(.frostWhite)
                    
                    Spacer()
                    
                    Text(batteryMonitor.batteryInfo.healthStatus.label)
                        .font(.subheadline)
                        .foregroundColor(.frostWhite)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(healthColor)
                        .clipShape(Capsule())
                }
                
                // Health bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Maximum Capacity")
                            .font(.subheadline)
                            .foregroundColor(.slateGray)
                        Spacer()
                        Text("\(Int(batteryMonitor.batteryInfo.healthPercent))%")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(healthColor)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.slateGray.opacity(0.2))
                            
                            Capsule()
                                .fill(healthColor)
                                .frame(width: geo.size.width * (batteryMonitor.batteryInfo.healthPercent / 100))
                        }
                    }
                    .frame(height: 10)
                }
                
                Text("This measures the battery's capacity relative to when it was new.")
                    .font(.caption)
                    .foregroundColor(.slateGray)
            }
        }
    }
    
    private var healthColor: Color {
        switch batteryMonitor.batteryInfo.healthStatus {
        case .good: return .emeraldGreen
        case .fair: return .orange
        case .poor: return .red
        }
    }
    
    private var additionalInfoCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                InfoRow(label: "Cycle Count", value: "\(batteryMonitor.batteryInfo.cycleCount)")
                
                Divider()
                    .background(Color.slateGray.opacity(0.3))
                
                InfoRow(label: "Design Capacity", value: "\(batteryMonitor.batteryInfo.designCapacity) mAh")
                
                Divider()
                    .background(Color.slateGray.opacity(0.3))
                
                InfoRow(label: "Current Max Capacity", value: "\(batteryMonitor.batteryInfo.maxCapacity) mAh")
                
                if batteryMonitor.batteryInfo.temperature > 0 {
                    Divider()
                        .background(Color.slateGray.opacity(0.3))
                    
                    InfoRow(label: "Temperature", value: "\(batteryMonitor.batteryInfo.temperature)°C")
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.slateGray)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.frostWhite)
        }
    }
}

#Preview {
    BatteryHealthView()
        .frame(width: 700, height: 600)
        .background(Color.backgroundGradient)
}
