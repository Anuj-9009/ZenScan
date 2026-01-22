import Foundation
import IOKit.ps

/// Battery health monitor
class BatteryMonitor: ObservableObject {
    @Published var batteryInfo: BatteryInfo = BatteryInfo()
    
    init() {
        refresh()
    }
    
    func refresh() {
        batteryInfo = getBatteryInfo()
    }
    
    private func getBatteryInfo() -> BatteryInfo {
        var info = BatteryInfo()
        
        guard let powerSources = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(powerSources)?.takeRetainedValue() as? [CFTypeRef] else {
            return info
        }
        
        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(powerSources, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            
            if let type = description[kIOPSTypeKey] as? String, type == kIOPSInternalBatteryType {
                info.isPresent = true
                info.currentCapacity = description[kIOPSCurrentCapacityKey] as? Int ?? 0
                info.maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 100
                info.isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
                info.isPluggedIn = description[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
                
                if let timeRemaining = description[kIOPSTimeToEmptyKey] as? Int, timeRemaining > 0 {
                    info.timeRemaining = timeRemaining
                }
                if let timeToFull = description[kIOPSTimeToFullChargeKey] as? Int, timeToFull > 0 {
                    info.timeToFullCharge = timeToFull
                }
            }
        }
        
        // Get cycle count and design capacity from IORegistry
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        if service != 0 {
            defer { IOObjectRelease(service) }
            
            var props: Unmanaged<CFMutableDictionary>?
            let result = IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0)
            
            if result == KERN_SUCCESS, let properties = props?.takeRetainedValue() as? [String: Any] {
                info.cycleCount = properties["CycleCount"] as? Int ?? 0
                info.designCapacity = properties["DesignCapacity"] as? Int ?? 0
                info.temperature = (properties["Temperature"] as? Int ?? 0) / 100
                
                // Calculate health percentage
                if info.designCapacity > 0 {
                    info.healthPercent = Double(info.maxCapacity) / Double(info.designCapacity) * 100
                }
            }
        }
        
        return info
    }
}

/// Battery information model
struct BatteryInfo {
    var isPresent = false
    var currentCapacity = 0
    var maxCapacity = 100
    var designCapacity = 0
    var cycleCount = 0
    var isCharging = false
    var isPluggedIn = false
    var timeRemaining = 0
    var timeToFullCharge = 0
    var temperature = 0
    var healthPercent: Double = 100
    
    var chargePercent: Int {
        guard maxCapacity > 0 else { return 0 }
        return Int(Double(currentCapacity) / Double(maxCapacity) * 100)
    }
    
    var healthStatus: HealthStatus {
        if healthPercent >= 80 {
            return .good
        } else if healthPercent >= 60 {
            return .fair
        } else {
            return .poor
        }
    }
    
    var formattedTimeRemaining: String {
        if timeRemaining <= 0 {
            return isPluggedIn ? "Plugged In" : "Calculating..."
        }
        let hours = timeRemaining / 60
        let minutes = timeRemaining % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    var formattedTimeToFull: String {
        if timeToFullCharge <= 0 {
            return isCharging ? "Calculating..." : "Not Charging"
        }
        let hours = timeToFullCharge / 60
        let minutes = timeToFullCharge % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

/// Battery health status
enum HealthStatus {
    case good
    case fair
    case poor
    
    var color: String {
        switch self {
        case .good: return "emeraldGreen"
        case .fair: return "orange"
        case .poor: return "red"
        }
    }
    
    var label: String {
        switch self {
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Service Recommended"
        }
    }
}
