import AppKit

// `KeyboardSwitcher status` prints state and exits; with no arguments it runs as a menu bar app.
if CommandLine.arguments.dropFirst().first == "status" {
    let display = Config.displayName ?? "External display"
    print("\(display): \(DisplayMonitor.isDisplayConnected ? "connected" : "not connected")")
    if Config.deviceAddresses.isEmpty { print("No devices chosen") }
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
