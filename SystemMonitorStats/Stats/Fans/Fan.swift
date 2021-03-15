public struct Fan {
    public let id: Int
    public let name: String
    public let minSpeed: Double
    public let maxSpeed: Double
    public var value: Double

    var state: Bool {
        get {
            return Store.shared.bool(key: "fan_\(self.id)", defaultValue: true)
        }
    }

    var formattedValue: String {
        get {
            return "\(Int(value)) RPM"
        }
    }
}
