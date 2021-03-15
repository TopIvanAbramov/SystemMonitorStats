import Foundation
import Cocoa

public class GPUStats: ReaderProtocol {
	public struct GPUs {
		public var list: [GPU_Info] = []
	}
	
	public struct GPU_Info {
		public let IOClass: String
		public let gpuModel: String

		public var utilization: Double? = nil
		
		init(IOClass: String, model: String) {
			self.IOClass = IOClass
			self.gpuModel = model
		}
	}
	
	private var gpus: GPUs = GPUs()
	
    
    /// Read information about GPU usage
    /// - Parameter callback: returns list of GPU's usage for each GPU
    
	public func read(callback: @escaping (GPUs) -> Void) {
		guard let accelerators = fetchIOService(kIOAcceleratorClassName) else {
			return
		}
		
		accelerators.forEach { (accelerator: NSDictionary) in
			guard let IOClass = accelerator.object(forKey: "IOClass") as? String else {
				print("Error: IOClass not found")
				return
			}
			
			guard let stats = accelerator["PerformanceStatistics"] as? [String:Any] else {
				print("PerformanceStatistics not found")
				return
			}
			
			let ioClass = IOClass.lowercased()
			var gpuModel: String = ""
			
			let utilization: Int? = stats["Device Utilization %"] as? Int ?? stats["GPU Activity(%)"] as? Int ?? nil
			
			if ioClass == "nvaccelerator" || ioClass.contains("nvidia") {
				gpuModel = "Nvidia Graphics"
			} else if ioClass.contains("amd") {
				gpuModel = "AMD Graphics"
			} else {
				gpuModel = "Intel Graphics"
			}
			
			if self.gpus.list.first(where: { $0.gpuModel == gpuModel }) == nil {
				self.gpus.list.append(GPU_Info(
					IOClass: IOClass,
					model: gpuModel
				))
			}
			guard let idx = self.gpus.list.firstIndex(where: { $0.gpuModel == gpuModel }) else {
				return
			}
			if let value = utilization {
				self.gpus.list[idx].utilization = Double(value)/100
			}
		}
		callback(self.gpus)
	}
}
