import Foundation
import IOKit
import Cocoa
import os.log
import IOKit.ps

public protocol value_t {
	
}

struct Battery_Usage: value_t {
    var powerSource: String = ""
    var state: String? = nil
    var isCharged: Bool = false
    var isCharging: Bool = false
    var level: Double = 0
    var cycles: Int = 0
    var health: Int = 0
    
    var amperage: Int = 0
    var voltage: Double = 0
    var temperature: Double = 0
    
    var ACwatts: Int = 0
    
    var timeToEmpty: Int = 0
    var timeToCharge: Int = 0

}

public class BatteryStats: ReaderProtocol {
    private var service: io_connect_t = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleSmartBattery"))
    
    private var source: CFRunLoopSource?
    private var loop: CFRunLoop?
    
    private var usage: Battery_Usage = Battery_Usage()
    
    func start() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        self.source = IOPSNotificationCreateRunLoopSource({ (context) in
        }, context).takeRetainedValue()
        
        self.loop = RunLoop.current.getCFRunLoop()
        CFRunLoopAddSource(self.loop, source, .defaultMode)
    }

    /// Read information about Battery usage
    /// - Parameter callback: returns different stats for Battery
    
	func read(callback: @escaping (Battery_Usage) -> ()) {
        let psInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let psList = IOPSCopyPowerSourcesList(psInfo).takeRetainedValue() as [CFTypeRef]
        
        if psList.count == 0 {
            return
        }
        
        for ps in psList {
            if let list = IOPSGetPowerSourceDescription(psInfo, ps).takeUnretainedValue() as? Dictionary<String, Any> {
                self.usage.powerSource = list[kIOPSPowerSourceStateKey] as? String ?? "AC Power"
                self.usage.isCharged = list[kIOPSIsChargedKey] as? Bool ?? false
                self.usage.isCharging = self.getBoolValue("IsCharging" as CFString) ?? false
                self.usage.level = Double(list[kIOPSCurrentCapacityKey] as? Int ?? 0) / 100
                
                if let time = list[kIOPSTimeToEmptyKey] as? Int {
                    self.usage.timeToEmpty = Int(time)
                }
                if let time = list[kIOPSTimeToFullChargeKey] as? Int {
                    self.usage.timeToCharge = Int(time)
                }
                
                self.usage.cycles = self.getIntValue("CycleCount" as CFString) ?? 0
                
                let maxCapacity = self.getIntValue("MaxCapacity" as CFString) ?? 1
                let designCapacity = self.getIntValue("DesignCapacity" as CFString) ?? 1
                #if arch(x86_64)
                self.usage.health = (100 * maxCapacity) / designCapacity
                self.usage.state = list[kIOPSBatteryHealthKey] as? String
                #else
                self.usage.health = maxCapacity
                #endif
                
                self.usage.amperage = self.getIntValue("Amperage" as CFString) ?? 0
                self.usage.voltage = self.getVoltage() ?? 0
                self.usage.temperature = self.getTemperature() ?? 0
                
                var ACwatts: Int = 0
                if let ACDetails = IOPSCopyExternalPowerAdapterDetails() {
                    if let ACList = ACDetails.takeUnretainedValue() as? Dictionary<String, Any> {
                        guard let watts = ACList[kIOPSPowerAdapterWattsKey] else {
                            return
                        }
                        ACwatts = Int(watts as! Int)
                    }
                }
                self.usage.ACwatts = ACwatts
                
                callback(self.usage)
            }
        }
    }
    
    private func getBoolValue(_ forIdentifier: CFString) -> Bool? {
        if let value = IORegistryEntryCreateCFProperty(self.service, forIdentifier, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as? Bool
        }
        return nil
    }
    
    private func getIntValue(_ identifier: CFString) -> Int? {
        if let value = IORegistryEntryCreateCFProperty(self.service, identifier, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as? Int
        }
        return nil
    }
    
    private func getDoubleValue(_ identifier: CFString) -> Double? {
        if let value = IORegistryEntryCreateCFProperty(self.service, identifier, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as? Double
        }
        return nil
    }
    
    private func getVoltage() -> Double? {
        if let value = self.getDoubleValue("Voltage" as CFString) {
            return value / 1000.0
        }
        return nil
    }
    
    private func getTemperature() -> Double? {
        if let value = IORegistryEntryCreateCFProperty(self.service, "Temperature" as CFString, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as! Double / 100.0
        }
        return nil
    }
}
