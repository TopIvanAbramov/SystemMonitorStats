import Cocoa

public struct RAM_Usage {
	var total: Double
	var free: Double
	
	var app: Double
	
	public var usage: Double {
		get {
			return Double((self.total - self.free) / self.total)
		}
	}
}


public class RAMStats: ReaderProtocol {
    
    /// Parse command line arguments
    /// - Parameter line: command line to parse
    /// - Returns: parsed info about process: command, pid and usage
    
    internal func parseProcessLine(_ line: String) -> (String, Int, Double) {
        var str = line.trimmingCharacters(in: .whitespaces)
        let pidString = str.findAndCrop(pattern: "^\\d+")
        let usageString = str.suffix(5)
        var command = str.replacingOccurrences(of: pidString, with: "")
        command = command.replacingOccurrences(of: usageString, with: "")
        
        if let regex = try? NSRegularExpression(pattern: " (\\+|\\-)*$", options: .caseInsensitive) {
            command = regex.stringByReplacingMatches(in: command, options: [], range: NSRange(location: 0, length:  command.count), withTemplate: "")
        }
        
        let pid = Int(pidString.filter("01234567890.".contains)) ?? 0
        let usage = Double(usageString.filter("01234567890.".contains)) ?? 0
        
        return (command, pid, usage)
    }
	
    /// Read information about RAM usage
    /// - Parameter callback: returns list of RAM's usage for each process
    
	public func read(callback: @escaping ([TopProcess]) -> ()) {
		let numberOfProcesses = 10
		
		let task = Process()
		task.launchPath = "/usr/bin/top"
		task.arguments = ["-l", "1", "-o", "mem", "-n", "\(numberOfProcesses)", "-stats", "pid,command,mem"]
		
		let outputPipe = Pipe()
		let errorPipe = Pipe()
		
		task.standardOutput = outputPipe
		task.standardError = errorPipe
		
		do {
			try task.run()
		} catch let error {
			print("Error: \(error.localizedDescription)")
			return
		}
		
		let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
		let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
		let output = String(decoding: outputData, as: UTF8.self)
		_ = String(decoding: errorData, as: UTF8.self)
		
		if output.isEmpty {
			return
		}
		
		var processes: [TopProcess] = []
		output.enumerateLines { (line, _) -> () in
			if line.matches("^\\d+ +.* +\\d+[A-Z]*\\+?\\-? *$") {
                var command: String, pid: Int, usage: Double
                (command, pid, usage) = self.parseProcessLine(line)

				var name: String? = nil
				if let app = NSRunningApplication(processIdentifier: pid_t(pid) ) {
					name = app.localizedName ?? nil
				}
				
				let process = TopProcess(pid: pid, command: command, name: name, usage: usage * Double(1024 * 1024))
				processes.append(process)
			}
		}
		callback(processes)
	}
}
