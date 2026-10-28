import AppKit
import ServiceManagement

/// Menu bar app: the devices belong to whichever Mac has the display attached.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = DisplayMonitor()
    private var devices: [DeviceController] = []
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        devices = Config.deviceAddresses.compactMap(DeviceController.init(address:))
        devices.forEach { $0.onStatusChange = { [weak self] in self?.rebuildMenu() } }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "KeyboardSwitcher")

        monitor.onChange = { [weak self] connected in self?.displayChanged(connected) }
        monitor.start()
        displayChanged(DisplayMonitor.isDisplayConnected)
    }

    private func displayChanged(_ connected: Bool) {
        log("\(Config.displayName) \(connected ? "connected" : "not connected")")
        if Config.automaticSwitching {
            connected ? claimAll() : releaseAll()
        }
        rebuildMenu()
    }

    @objc private func claimAll() { devices.forEach { $0.claim() } }
    @objc private func releaseAll() { devices.forEach { $0.release() } }

    @objc private func toggleAutomatic() {
        Config.automaticSwitching.toggle()
        if Config.automaticSwitching { displayChanged(DisplayMonitor.isDisplayConnected) }
        rebuildMenu()
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled { try service.unregister() } else { try service.register() }
        } catch {
            log("launch at login: \(error.localizedDescription)")
        }
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        let display = DisplayMonitor.isDisplayConnected ? "connected" : "not connected"
        menu.addItem(withTitle: "\(Config.displayName): \(display)", action: nil, keyEquivalent: "")
        for device in devices {
            let state = device.isConnected ? "connected" : device.isPaired ? "paired" : "not paired"
            menu.addItem(withTitle: "\(device.name): \(state)", action: nil, keyEquivalent: "")
        }
        menu.addItem(.separator())
        menu.addItem(item("Take Devices Now", #selector(claimAll)))
        menu.addItem(item("Release Devices Now", #selector(releaseAll)))
        menu.addItem(.separator())
        menu.addItem(item("Switch Automatically", #selector(toggleAutomatic), on: Config.automaticSwitching))
        menu.addItem(item("Launch at Login", #selector(toggleLaunchAtLogin), on: SMAppService.mainApp.status == .enabled))
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    private func item(_ title: String, _ action: Selector, on: Bool = false) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = on ? .on : .off
        return item
    }
}
