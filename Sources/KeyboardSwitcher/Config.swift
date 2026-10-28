import Foundation

/// Settings live in UserDefaults (domain `com.igonin.KeyboardSwitcher`) so they can be changed with `defaults write`.
enum Config {
    private static let defaults = UserDefaults.standard

    /// Bluetooth addresses of the devices that follow the display.
    static var deviceAddresses: [String] {
        defaults.stringArray(forKey: "deviceAddresses") ?? [
            "38:09:FB:1B:6D:2A", // Magic Keyboard
            "3C:7D:0A:5C:A4:77", // Magic Trackpad
        ]
    }

    /// Substring matched against the screen's localized name.
    static var displayName: String {
        defaults.string(forKey: "displayName") ?? "Studio Display"
    }

    static var automaticSwitching: Bool {
        get { defaults.object(forKey: "automaticSwitching") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "automaticSwitching") }
    }
}
