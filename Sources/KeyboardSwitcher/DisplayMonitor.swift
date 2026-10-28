import AppKit

/// Reports whether the target display is attached, debouncing the burst of
/// screen-parameter notifications macOS sends while reconfiguring.
final class DisplayMonitor {
    var onChange: ((Bool) -> Void)?
    private var pending: DispatchWorkItem?

    static var externalDisplayNames: [String] {
        NSScreen.screens.filter { !isBuiltIn($0) }.map(\.localizedName)
    }

    static var isDisplayConnected: Bool {
        let names = externalDisplayNames
        guard let target = Config.displayName else { return !names.isEmpty }
        return names.contains(target)
    }

    private static func isBuiltIn(_ screen: NSScreen) -> Bool {
        guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { return false }
        return CGDisplayIsBuiltin(id) != 0
    }

    func start() {
        let center = NotificationCenter.default
        center.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            self?.schedule()
        }
        // Covers being unplugged while asleep: no screen notification fires then.
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.schedule()
        }
    }

    private func schedule() {
        pending?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.onChange?(Self.isDisplayConnected)
        }
        pending = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: item)
    }
}
