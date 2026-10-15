import Foundation

/// Run with `--debug` (or WINDOW_PIN_DEBUG=1) to print what the app is doing.
let debugEnabled = CommandLine.arguments.contains("--debug")
    || ProcessInfo.processInfo.environment["WINDOW_PIN_DEBUG"] == "1"

func debugLog(_ message: @autoclosure () -> String) {
    guard debugEnabled else { return }
    print("[pin] \(message())")
    fflush(stdout)
}
