import AppKit
import IOBluetooth
import ServiceManagement

/// Menu bar app: the chosen devices belong to whichever Mac has the chosen display attached.
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let monitor = DisplayMonitor()
    private var devices: [DeviceController] = []
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        rotateLogIfNeeded()
        loadDevices()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "KeyboardSwitcher")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        monitor.onChange = { [weak self] connected in self?.displayChanged(connected) }
        monitor.start()
        displayChanged(DisplayMonitor.isDisplayConnected)
    }

    private func loadDevices() {
        devices.forEach { $0.stop() }
        devices = Config.deviceAddresses.compactMap(DeviceController.init(address:))
    }

    private func displayChanged(_ connected: Bool) {
        log("\(displayLabel) \(connected ? "connected" : "not connected")")
        if Config.automaticSwitching {
            connected ? claimAll() : releaseAll()
        }
    }

    private var displayLabel: String { Config.displayName ?? "External display" }

    @objc private func claimAll() { devices.forEach { $0.claim() } }
    @objc private func releaseAll() { devices.forEach { $0.release() } }

    @objc private func toggleDevice(_ sender: NSMenuItem) {
        guard let address = sender.representedObject as? String else { return }
        var addresses = Config.deviceAddresses
        if let index = addresses.firstIndex(of: address) {
            addresses.remove(at: index)
        } else {
            addresses.append(address)
        }
        Config.deviceAddresses = addresses
        loadDevices()
        displayChanged(DisplayMonitor.isDisplayConnected)
    }

    @objc private func chooseDisplay(_ sender: NSMenuItem) {
        Config.displayName = sender.representedObject as? String
        displayChanged(DisplayMonitor.isDisplayConnected)
    }

    @objc private func toggleAutomatic() {
        Config.automaticSwitching.toggle()
        if Config.automaticSwitching { displayChanged(DisplayMonitor.isDisplayConnected) }
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled { try service.unregister() } else { try service.register() }
        } catch {
            log("launch at login: \(error.localizedDescription)")
        }
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let display = DisplayMonitor.isDisplayConnected ? "connected" : "not connected"
        menu.addItem(withTitle: "\(displayLabel): \(display)", action: nil, keyEquivalent: "")
        if devices.isEmpty {
            menu.addItem(withTitle: "Choose your keyboard and trackpad under Devices", action: nil, keyEquivalent: "")
        }
        for device in devices {
            let state = device.isConnected ? "connected" : device.isPaired ? "paired" : "not paired"
            menu.addItem(withTitle: "\(device.name): \(state)", action: nil, keyEquivalent: "")
        }
        menu.addItem(.separator())
        menu.addItem(submenu("Devices", deviceItems()))
        menu.addItem(submenu("Display", displayItems()))
        menu.addItem(.separator())
        menu.addItem(item("Take Devices Now", #selector(claimAll)))
        menu.addItem(item("Release Devices Now", #selector(releaseAll)))
        menu.addItem(.separator())
        menu.addItem(item("Switch Automatically", #selector(toggleAutomatic), on: Config.automaticSwitching))
        menu.addItem(item("Launch at Login", #selector(toggleLaunchAtLogin), on: SMAppService.mainApp.status == .enabled))
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    /// Paired and recently seen keyboards, mice and trackpads, plus anything already chosen.
    private func deviceItems() -> [NSMenuItem] {
        let known = (IOBluetoothDevice.pairedDevices() ?? []) + (IOBluetoothDevice.recentDevices(20) ?? [])
        var candidates = known
            .compactMap { $0 as? IOBluetoothDevice }
            .filter { $0.deviceClassMajor == kBluetoothDeviceClassMajorPeripheral }
            .compactMap { $0.addressString?.uppercased().replacingOccurrences(of: "-", with: ":") }
        candidates += Config.deviceAddresses
        var seen = Set<String>()
        let items = candidates.filter { seen.insert($0).inserted }.map { address -> NSMenuItem in
            let name = IOBluetoothDevice(addressString: address)?.nameOrAddress ?? address
            let item = self.item(name, #selector(toggleDevice(_:)), on: Config.deviceAddresses.contains(address))
            item.representedObject = address
            return item
        }
        if items.isEmpty {
            return [NSMenuItem(title: "No keyboards or trackpads found. Pair one first.", action: nil, keyEquivalent: "")]
        }
        return items
    }

    private func displayItems() -> [NSMenuItem] {
        let any = item("Any External Display", #selector(chooseDisplay(_:)), on: Config.displayName == nil)
        var names = DisplayMonitor.externalDisplayNames
        if let chosen = Config.displayName, !names.contains(chosen) { names.append(chosen) }
        var seen = Set<String>()
        return [any] + names.filter { seen.insert($0).inserted }.map { name in
            let item = self.item(name, #selector(chooseDisplay(_:)), on: Config.displayName == name)
            item.representedObject = name
            return item
        }
    }

    private func submenu(_ title: String, _ items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu()
        items.forEach(menu.addItem)
        item.submenu = menu
        return item
    }

    private func item(_ title: String, _ action: Selector, on: Bool = false) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = on ? .on : .off
        return item
    }
}
