import Foundation

let logURL = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Logs/KeyboardSwitcher.log")

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

/// Keeps one previous log around once the current one passes 1 MB.
func rotateLogIfNeeded() {
    let size = (try? FileManager.default.attributesOfItem(atPath: logURL.path)[.size] as? Int) ?? 0
    guard size > 1_000_000 else { return }
    let old = logURL.deletingPathExtension().appendingPathExtension("old.log")
    try? FileManager.default.removeItem(at: old)
    try? FileManager.default.moveItem(at: logURL, to: old)
}
