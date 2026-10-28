import Foundation

/// Settings live in UserDefaults (domain `com.igonin.KeyboardSwitcher`), set from the menu.
enum Config {
    private static let defaults = UserDefaults.standard

    /// Bluetooth addresses of the devices that follow the display.
    static var deviceAddresses: [String] {
        get { defaults.stringArray(forKey: "deviceAddresses") ?? [] }
        set { defaults.set(newValue, forKey: "deviceAddresses") }
    }

    /// Localized name of the display that triggers switching; nil means any external display.
    static var displayName: String? {
        get { defaults.string(forKey: "displayName") }
        set { defaults.set(newValue, forKey: "displayName") }
    }

    static var automaticSwitching: Bool {
        get { defaults.object(forKey: "automaticSwitching") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "automaticSwitching") }
    }
}
