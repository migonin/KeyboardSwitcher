import Foundation
import IOBluetooth

/// Claims (pair + connect) or releases (unpair) a single Bluetooth device.
///
/// A Magic Keyboard/Trackpad is bonded to one host at a time. Releasing removes
/// the pairing on this Mac, which lets the device accept pairing from the other Mac.
/// Claiming keeps retrying, because the other Mac may still hold the device
/// (for example, it was unplugged while asleep and releases only once it wakes).
final class DeviceController: NSObject, IOBluetoothDevicePairDelegate {
    let address: String
    var onStatusChange: (() -> Void)?

    private let device: IOBluetoothDevice
    private var wantsClaim = false
    private var busy = false
    private var lastConnectFailed = false
    private var pairing: IOBluetoothDevicePair?
    private var retryTimer: Timer?

    init?(address: String) {
        guard let device = IOBluetoothDevice(addressString: address) else { return nil }
        self.address = address
        self.device = device
    }

    var name: String { device.nameOrAddress ?? address }
    var isConnected: Bool { device.isConnected() }
    var isPaired: Bool { device.isPaired() }

    func claim() {
        wantsClaim = true
        attempt()
        if retryTimer == nil {
            retryTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in self?.attempt() }
        }
    }

    func release() {
        wantsClaim = false
        stopRetrying()
        pairing?.stop()
        pairing = nil
        busy = false
        guard device.isPaired() else { return }
        log("releasing \(name)")
        device.closeConnection()
        // IOBluetooth has no public unpair API; `remove` is what System Settings uses.
        device.perform(Selector(("remove")))
        onStatusChange?()
    }

    private func attempt() {
        guard wantsClaim, !busy else { return }
        if device.isConnected() {
            log("\(name) connected")
            stopRetrying()
            onStatusChange?()
            return
        }
        busy = true
        // Re-pairing an already paired device replaces a stale bond, so a failed
        // connection on a paired device falls through to pairing on the next attempt.
        if device.isPaired() && !lastConnectFailed {
            log("connecting \(name)")
            let result = device.openConnection(self)
            if result != kIOReturnSuccess { finishConnect(status: result) }
        } else {
            log("pairing \(name)")
            let pair = IOBluetoothDevicePair(device: device)!
            pair.delegate = self
            pairing = pair
            if pair.start() != kIOReturnSuccess { finishPairing(error: kIOReturnError) }
        }
    }

    private func finishConnect(status: IOReturn) {
        busy = false
        lastConnectFailed = status != kIOReturnSuccess
        if lastConnectFailed { log("connect \(name) failed: \(String(format: "0x%x", status))") }
        attempt()
    }

    private func finishPairing(error: IOReturn) {
        pairing = nil
        busy = false
        if error == kIOReturnSuccess {
            log("paired \(name)")
            lastConnectFailed = false
            attempt()
        } else {
            log("pairing \(name) failed: \(String(format: "0x%x", error)); will retry")
        }
    }

    private func stopRetrying() {
        retryTimer?.invalidate()
        retryTimer = nil
    }

    // MARK: - IOBluetoothDevice openConnection target

    @objc func connectionComplete(_ device: IOBluetoothDevice!, status: IOReturn) {
        finishConnect(status: status)
    }

    // MARK: - IOBluetoothDevicePairDelegate

    func devicePairingUserConfirmationRequest(_ sender: Any!, numericValue: BluetoothNumericValue) {
        (sender as? IOBluetoothDevicePair)?.replyUserConfirmation(true)
    }

    func devicePairingFinished(_ sender: Any!, error: IOReturn) {
        guard (sender as AnyObject) === pairing else { return }
        finishPairing(error: error)
    }
}

private let logURL = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Logs/KeyboardSwitcher.log")

/// Prints and appends to ~/Library/Logs/KeyboardSwitcher.log, since the app has no visible stdout.
func log(_ message: String) {
    let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
    print(line, terminator: "")
    fflush(stdout)
    if let handle = try? FileHandle(forWritingTo: logURL) {
        handle.seekToEndOfFile()
        handle.write(Data(line.utf8))
        try? handle.close()
    } else {
        try? Data(line.utf8).write(to: logURL)
    }
}
