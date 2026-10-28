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

    private let device: IOBluetoothDevice
    private var wantsClaim = false
    private var busy = false
    private var lastConnectFailed = false
    /// Last failure logged, so retries every 5 seconds don't flood the log.
    private var lastLoggedFailure: String?
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
        guard !wantsClaim else { return }
        wantsClaim = true
        attempt()
        if wantsClaim && retryTimer == nil {
            retryTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in self?.attempt() }
        }
    }

    func release() {
        stop()
        guard device.isPaired() else { return }
        log("releasing \(name)")
        device.closeConnection()
        // IOBluetooth has no public unpair API; `remove` is what System Settings uses.
        device.perform(Selector(("remove")))
    }

    /// Stops claiming without touching the pairing.
    func stop() {
        wantsClaim = false
        retryTimer?.invalidate()
        retryTimer = nil
        pairing?.stop()
        pairing = nil
        busy = false
        lastLoggedFailure = nil
    }

    private func attempt() {
        guard wantsClaim, !busy else { return }
        if device.isConnected() {
            if retryTimer != nil { log("\(name) connected") }
            stop()
            return
        }
        busy = true
        // Re-pairing an already paired device replaces a stale bond, so a failed
        // connection on a paired device falls through to pairing on the next attempt.
        if device.isPaired() && !lastConnectFailed {
            let result = device.openConnection(self)
            if result != kIOReturnSuccess { finishConnect(status: result) }
        } else {
            let pair = IOBluetoothDevicePair(device: device)!
            pair.delegate = self
            pairing = pair
            if pair.start() != kIOReturnSuccess { finishPairing(error: kIOReturnError) }
        }
    }

    private func finishConnect(status: IOReturn) {
        busy = false
        lastConnectFailed = status != kIOReturnSuccess
        if lastConnectFailed { logFailure("connecting \(name) failed: \(hex(status))") }
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
            logFailure("pairing \(name) failed: \(hex(error)); retrying every 5 seconds")
        }
    }

    private func logFailure(_ message: String) {
        guard message != lastLoggedFailure else { return }
        lastLoggedFailure = message
        log(message)
    }

    private func hex(_ value: IOReturn) -> String { String(format: "0x%x", value) }

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
