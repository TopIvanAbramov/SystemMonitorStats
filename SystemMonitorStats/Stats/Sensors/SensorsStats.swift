import Foundation

public class SensorsStats: ReaderProtocol {
    internal var list: [Sensor_t] = []
    private var smc: UnsafePointer<SMCService>
    
    init(_ smc: UnsafePointer<SMCService>) {
        self.smc = smc
        
        var available: [String] = self.smc.pointee.getAllKeys()
        var list: [Sensor_t] = []
        
        available = available.filter({ (key: String) -> Bool in
            switch key.prefix(1) {
            case "T", "V", "P", "F": return true
            default: return false
            }
        })
        
        SensorsList.forEach { (s: Sensor_t) in
            if let idx = available.firstIndex(where: { $0 == s.key }) {
                list.append(s)
                available.remove(at: idx)
            }
        }
        
        SensorsList.filter{ $0.key.contains("%") }.forEach { (s: Sensor_t) in
            var index = 1
            for i in 0..<10 {
                let key = s.key.replacingOccurrences(of: "%", with: "\(i)")
                if available.firstIndex(where: { $0 == key }) != nil {
                    var sensor = s.copy()
                    sensor.key = key
                    sensor.name = s.name.replacingOccurrences(of: "%", with: "\(index)")
                    
                    list.append(sensor)
                    index += 1
                }
            }
        }
        
        for (index, sensor) in list.enumerated().reversed() {
            if let newValue = self.smc.pointee.getValue(sensor.key) {
                // Remove the temperature sensor, if SMC report more that 110 C degree.
                if sensor.type == SensorType.Temperature.rawValue && newValue > 110 {
                    list.remove(at: index)
                    continue
                }
                
                if let idx = list.firstIndex(where: { $0.key == sensor.key }) {
                    list[idx].value = newValue
                }
            }
        }
        
        self.list = list
    }
    
    /// Read information about Sensors usage
    /// - Parameter callback: returns list of Sensror's usage for each Sensor
    
	func read(callback: @escaping ([Sensor_t]) -> Void) {
        callback(self.list)
    }
}
