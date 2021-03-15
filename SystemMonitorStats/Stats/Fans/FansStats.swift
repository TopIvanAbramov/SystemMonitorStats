import Foundation
import os.log

public class FansStats: ReaderProtocol {
    private var smc: UnsafePointer<SMCService>
    internal var list: [Fan] = []
    public var readyCallback: () -> Void = {}
    
    init(smc: UnsafePointer<SMCService>) {
        self.smc = smc
        
        guard let count = smc.pointee.getValue("FNum") else {
            return
        }
        
        for i in 0..<Int(count) {
            self.list.append(Fan(
                id: i,
                name: smc.pointee.getStringValue("F\(i)ID") ?? "Fan #\(i)",
                minSpeed: smc.pointee.getValue("F\(i)Mn") ?? 1,
                maxSpeed: smc.pointee.getValue("F\(i)Mx") ?? 1,
                value: smc.pointee.getValue("F\(i)Ac") ?? 0
            ))
        }
    }
    
    /// Read information about Fan usage
    /// - Parameter callback: returns list of Fan's usage for each Fan
    
    public func read(callback: @escaping ([Fan]) -> Void) {
//		insert your update value here)
        callback(self.list)
    }
}
