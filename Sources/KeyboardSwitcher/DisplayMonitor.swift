import AppKit

/// Reports whether the target display is attached, debouncing the burst of
/// screen-parameter notifications macOS sends while reconfiguring.
final class DisplayMonitor {
    var onChange: ((Bool) -> Void)?
    private var pending: DispatchWorkItem?

    static var isDisplayConnected: Bool {
        NSScreen.screens.contains { $0.localizedName.localizedCaseInsensitiveContains(Config.displayName) }
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
