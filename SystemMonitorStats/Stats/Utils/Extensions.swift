import Cocoa

extension String: LocalizedError {
    public mutating func findAndCrop(pattern: String) -> String {
        let regex = try! NSRegularExpression(pattern: pattern)
        let stringRange = NSRange(location: 0, length: self.utf16.count)
        var line = self
        
        if let searchRange = regex.firstMatch(in: self, options: [], range: stringRange) {
            let start = self.index(self.startIndex, offsetBy: searchRange.range.lowerBound)
            let end = self.index(self.startIndex, offsetBy: searchRange.range.upperBound)
            let value  = String(self[start..<end]).trimmingCharacters(in: .whitespaces)
            line = self.replacingOccurrences(
                of: value,
                with: "",
                options: .regularExpression
            )
            self = line.trimmingCharacters(in: .whitespaces)
            return value.trimmingCharacters(in: .whitespaces)
        }
        
        return ""
    }
    
    public func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
}

public extension Int {
    init(fromFPE2 bytes: (UInt8, UInt8)) {
        self = (Int(bytes.0) << 6) + (Int(bytes.1) >> 2)
    }
}

extension Float {
    init?(_ bytes: [UInt8]) {
        self = bytes.withUnsafeBytes {
            return $0.load(fromByteOffset: 0, as: Self.self)
        }
    }
}

public extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension UInt32 {
    init(bytes: (UInt8, UInt8, UInt8, UInt8)) {
        self = UInt32(bytes.0) << 24 | UInt32(bytes.1) << 16 | UInt32(bytes.2) << 8 | UInt32(bytes.3)
    }
}

extension UInt16 {
    init(bytes: (UInt8, UInt8)) {
        self = UInt16(bytes.0) << 8 | UInt16(bytes.1)
    }
}

extension FourCharCode {
    init(fromString str: String) {
        precondition(str.count == 4)
        
        self = str.utf8.reduce(0) { sum, character in
            return sum << 8 | UInt32(character)
        }
    }
    
    func toString() -> String {
        return String(describing: UnicodeScalar(self >> 24 & 0xff)!) +
               String(describing: UnicodeScalar(self >> 16 & 0xff)!) +
               String(describing: UnicodeScalar(self >> 8  & 0xff)!) +
               String(describing: UnicodeScalar(self       & 0xff)!)
    }
}

extension Double {
    func readableSize() -> String {
        let sizes = ["B", "KB", "MB", "GB"]
        var index = 0
        var convertedValue = self
        while (convertedValue > 1024 && index < sizes.count - 1) {
            convertedValue = convertedValue / 1_000
            index += 1
        }
        return "\(NSString(format: "%.1f", convertedValue)) \(sizes[index])"
    }
}

extension UnitTemperature {
    static var current: UnitTemperature {
        let measureFormatter = MeasurementFormatter()
        let measurement = Measurement(value: 0, unit: UnitTemperature.celsius)
        return measureFormatter.string(from: measurement).hasSuffix("C") ? .celsius : .fahrenheit
    }
}
