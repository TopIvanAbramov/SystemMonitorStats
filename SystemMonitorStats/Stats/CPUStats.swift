import Foundation
import os.log
import AppKit

/// Process model
/// - Parameters:
///   - pid: process's pid
///   - command: command to call process
///   - name: name of process
///   - usage: CPU usage by process

public struct TopProcess {
	public var pid: Int
	public var command: String
	public var name: String?
	public var usage: Double
    
	public init(pid: Int, command: String, name: String?, usage: Double) {
		self.pid = pid
		self.command = command
		self.name = name
		self.usage = usage
	}
}

public class CPUStats: ReaderProtocol {
    
    /// Parse command line arguments
    /// - Parameter line: command line to parse
    /// - Returns: parsed info about process: command, pid and usage
    
    internal func parseProcessLine(_ line: String) -> (String, Int, Double) {
        var str = line.trimmingCharacters(in: .whitespaces)
        let pidString = str.findAndCrop(pattern: "^\\d+")
        let usageString = str.findAndCrop(pattern: "^[0-9,.]+ ")
        let command = str.trimmingCharacters(in: .whitespaces)
        
        let pid = Int(pidString) ?? 0
        let usage = Double(usageString.replacingOccurrences(of: ",", with: ".")) ?? 0
        return (command, pid, usage)
    }
    
    /// Read information about CPU usage
    /// - Parameter callback: returns list of CPU's usage for each process
    
	public func read(callback: @escaping ([TopProcess]) -> Void) {
		let task = Process()
		task.launchPath = "/bin/ps"
		task.arguments = ["-Aceo pid,pcpu,comm", "-r"]
		
		let outputPipe = Pipe()
		let errorPipe = Pipe()
		
		task.standardOutput = outputPipe
		task.standardError = errorPipe
		
		do {
			try task.run()
		} catch let error {
			print("Eror: \(error.localizedDescription)")
			return
		}
		
		let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
		let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
		let output = String(decoding: outputData, as: UTF8.self)
		_ = String(decoding: errorData, as: UTF8.self)
		
		if output.isEmpty {
			return
		}
		
		var index = 0
		var processes: [TopProcess] = []
		output.enumerateLines { (line, stop) -> () in
			if index != 0 {
                var command: String, pid: Int, usage: Double
                (command, pid, usage) = self.parseProcessLine(line)
				
				var name: String? = nil
				
				if let app = NSRunningApplication(processIdentifier: pid_t(pid) ) {
					name = app.localizedName ?? nil
				}
				
				processes.append(TopProcess(pid: pid, command: command, name: name, usage: usage))
			}
			
			index += 1
		}
		
		callback(processes)
	}
}
