import Foundation
import Cocoa
import SystemConfiguration
import CoreWLAN

/// Description: Network process model

public struct Network_Process {
    var time: Date = Date()
    var name: String = ""
    var download: Int = 0
    var upload: Int = 0
}

public typealias Bandwidth = (upload: Int64, download: Int64)


/// Description: Network stats model

public struct Network_Usage: value_t {
    var bandwidth: Bandwidth = (0, 0)
    var total: Bandwidth = (0, 0)
    
    var laddr: String? = nil // local ip
    
    mutating func reset() {
        self.bandwidth = (0, 0)
        
        self.laddr = nil
    }
}

public class NetworkStats: ReaderProtocol {
    public var store: UnsafePointer<Store>? = nil
    
    private var usage: Network_Usage = Network_Usage()
    
    private var reader: String {
        get {
            return self.store?.pointee.string(key: "Network_reader", defaultValue: "interface") ?? "interface"
        }
    }
    
    /// Read information about Network usage
    /// - Parameter callback: returns  Network's usage
    
    public func read(callback: @escaping (Network_Usage) -> Void) {
        let current: Bandwidth = self.reader == "interface" ? self.readInterfaceBandwidth() : self.readProcessBandwidth()
        
        // allows to reset the value to 0 when first read
        if self.usage.bandwidth.upload != 0 {
            self.usage.bandwidth.upload = current.upload - self.usage.bandwidth.upload
        }
        if self.usage.bandwidth.download != 0 {
            self.usage.bandwidth.download = current.download - self.usage.bandwidth.download
        }
        
        self.usage.bandwidth.upload = max(self.usage.bandwidth.upload, 0) // prevent negative upload value
        self.usage.bandwidth.download = max(self.usage.bandwidth.download, 0) // prevent negative download value
        
        self.usage.total.upload += self.usage.bandwidth.upload
        self.usage.total.download += self.usage.bandwidth.download
        
        callback(usage)
        
        self.usage.bandwidth.upload = current.upload
        self.usage.bandwidth.download = current.download
    }
    
    /// Description: get interface bandwidth
    /// - Returns: Bandwidth model
    
    private func readInterfaceBandwidth() -> Bandwidth {
        var interfaceAddresses: UnsafeMutablePointer<ifaddrs>? = nil
        var totalUpload: Int64 = 0
        var totalDownload: Int64 = 0
        guard getifaddrs(&interfaceAddresses) == 0 else {
            return (0, 0)
        }
        
        var pointer = interfaceAddresses
        while pointer != nil {
            defer { pointer = pointer?.pointee.ifa_next }
     
            
            if let ip = getLocalIP(pointer!), self.usage.laddr != ip {
                self.usage.laddr = ip
            }
            
            if let info = getBytesInfo(pointer!) {
                totalUpload += info.upload
                totalDownload += info.download
            }
        }
        freeifaddrs(interfaceAddresses)
        
        return (totalUpload, totalDownload)
    }
    
    
    /// Description: get proceses bandwidth
    /// - Returns: Bandwidth model
    
    private func readProcessBandwidth() -> Bandwidth {
        let task = Process()
        task.launchPath = "/usr/bin/nettop"
        task.arguments = ["-P", "-L", "1", "-k", "time,interface,state,rx_dupe,rx_ooo,re-tx,rtt_avg,rcvsize,tx_win,tc_class,tc_mgt,cc_algo,P,C,R,W,arch"]
        
        let outputPipe = Pipe()
        
        task.standardOutput = outputPipe
        
        do {
            try task.run()
        } catch let error {
			print(error)
            return (0, 0)
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        
        
        if output.isEmpty {
            return (0, 0)
        }

        var totalUpload: Int64 = 0
        var totalDownload: Int64 = 0
        var firstLine = false
        output.enumerateLines { (line, _) -> () in
            if !firstLine {
                firstLine = true
                return
            }
            
            let parsedLine = line.split(separator: ",")
            guard parsedLine.count >= 3 else {
                return
            }
            
            if let download = Int64(parsedLine[1]) {
                totalDownload += download
            }
            if let upload = Int64(parsedLine[2]) {
                totalUpload += upload
            }
        }
        
        return (totalUpload, totalDownload)
    }
    
    
    /// Description: get local IP address
    /// - Parameter pointer: IP adress pointer
    /// - Returns: string representation of IP address
    
    private func getLocalIP(_ pointer: UnsafeMutablePointer<ifaddrs>) -> String? {
        var addr = pointer.pointee.ifa_addr.pointee
        
        guard addr.sa_family == UInt8(AF_INET) else {
            return nil
        }
        
        var ip = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        getnameinfo(&addr, socklen_t(addr.sa_len), &ip, socklen_t(ip.count), nil, socklen_t(0), NI_NUMERICHOST)
        
        return String(cString: ip)
    }
    
    
    /// Description
    /// - Parameter pointer:  IP adress pointer
    /// - Returns: upload and download speeds
    
    private func getBytesInfo(_ pointer: UnsafeMutablePointer<ifaddrs>) -> (upload: Int64, download: Int64)? {
        let addr = pointer.pointee.ifa_addr.pointee
        
        guard addr.sa_family == UInt8(AF_LINK) else {
            return nil
        }
        
        let data: UnsafeMutablePointer<if_data>? = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
        return (upload: Int64(data?.pointee.ifi_obytes ?? 0), download: Int64(data?.pointee.ifi_ibytes ?? 0))
    }
}
