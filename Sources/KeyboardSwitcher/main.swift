import AppKit

// `KeyboardSwitcher status` prints state and exits; with no arguments it runs as a menu bar app.
if CommandLine.arguments.dropFirst().first == "status" {
    print("\(Config.displayName): \(DisplayMonitor.isDisplayConnected ? "connected" : "not connected")")
    for address in Config.deviceAddresses {
        guard let device = DeviceController(address: address) else { continue }
        print("\(device.name) [\(address)]: paired=\(device.isPaired) connected=\(device.isConnected)")
    }
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
