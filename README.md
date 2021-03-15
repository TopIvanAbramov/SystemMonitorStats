# 💻 macOS System Monitor
> System Monitor is an application for Mac, designed to inform you unobtrusively about the activity of your computer.

[![Swift Version][swift-image]][swift-url]
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity)
[![Ask Me Anything !](https://img.shields.io/badge/Ask%20me-anything-1abc9c.svg)](https://t.me/IvanAbramoov)
[![License][license-image]][license-url]

You can retrieve up-to-date technical data any time, like process load, CPU temperature, main memory consumption, storage space, disk activity, communication on network interfaces, etc.

![](header.png)

## ⚙️ Installation 

1. Create a Podfile, and add your dependencies:
```ruby
target 'MyApp' do
  pod 'SystemMonitorStats'
end
```

2. Add key `App Sandbox : NO` to entitlements

## 🕹 Usage example


```swift
import SystemMonitorStats

let stats = SystemMonitorStats()
var statsDescription = ""

systemMonitorStats.readerRAM.read { topProcesses in
			topProcesses.forEach { process in
				statsDescription += """
				    Name: \(process.name ?? process.command) \
				    RAM Usage: \(process.usage.readableSize())
                    		"""
			}
		}

print(statsDescription)
```


## 📝 Release History

* 1.0.0
    * Created library and documentation
* 0.4.0
    * Added Senors usage
* 0.3.0
    * Added Fans usage
* 0.2.0
    * Added RAM usage
* 0.1.0
    * CPU and GPU usage 

Distributed under the MIT license. See ``LICENSE`` for more information.

[https://github.com/TopIvanAbramov/SystemMonitorStats](https://github.com/TopIvanAbramov/SystemMonitorStats)

[swift-image]:https://img.shields.io/badge/swift-5.3.3-orange.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE
[travis-image]: https://img.shields.io/travis/dbader/node-datadog-metrics/master.svg
[travis-url]: https://travis-ci.org/dbader/node-datadog-metrics
