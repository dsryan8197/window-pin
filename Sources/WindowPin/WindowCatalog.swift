import AppKit
import CoreGraphics

/// A normal app window.
struct AppWindow: Equatable {
    let id: CGWindowID
    let ownerPID: pid_t
    let ownerName: String
    let title: String
    /// Global display coordinates, origin at the top-left of the primary display.
    let bounds: CGRect
    /// False while minimised or on another desktop.
    let isOnScreen: Bool

    var displayName: String { title.isEmpty ? ownerName : title }

    /// "App — Title", or just the app name for untitled windows.
    var menuTitle: String {
        guard !title.isEmpty, title != ownerName else { return ownerName }
        let full = "\(ownerName) — \(title)"
        return full.count > 70 ? String(full.prefix(69)) + "…" : full
    }
}

enum WindowCatalog {
    private static let ignoredOwners: Set<String> = ["Window Server", "Dock", "Control Center", "Notification Center"]

    /// On-screen app windows, front-most first, excluding this app's own. Titles of other
    /// apps' windows are only filled in when the app has Screen Recording permission.
    static func onScreenWindows() -> [AppWindow] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        let ownPID = ProcessInfo.processInfo.processIdentifier
        return info.compactMap { entry in
            guard let layer = entry[kCGWindowLayer as String] as? Int, layer == 0,
                  let pid = entry[kCGWindowOwnerPID as String] as? pid_t, pid != ownPID,
                  let window = window(from: entry),
                  !ignoredOwners.contains(window.ownerName),
                  window.bounds.width >= 80, window.bounds.height >= 60
            else { return nil }
            return window
        }
    }

    /// The front-most window of the front-most app.
    static func frontWindow() -> AppWindow? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return nil }
        return onScreenWindows().first { $0.ownerPID == pid }
    }

    /// The current state of one window, on screen or not. Nil once it has closed.
    static func window(id: CGWindowID) -> AppWindow? {
        guard let info = CGWindowListCopyWindowInfo([.optionIncludingWindow], id) as? [[String: Any]],
              let entry = info.first
        else { return nil }
        return window(from: entry)
    }

    private static func window(from entry: [String: Any]) -> AppWindow? {
        guard let id = entry[kCGWindowNumber as String] as? CGWindowID,
              let pid = entry[kCGWindowOwnerPID as String] as? pid_t,
              let boundsInfo = entry[kCGWindowBounds as String] as? NSDictionary,
              let bounds = CGRect(dictionaryRepresentation: boundsInfo as CFDictionary)
        else { return nil }
        return AppWindow(
            id: id,
            ownerPID: pid,
            ownerName: entry[kCGWindowOwnerName as String] as? String ?? "",
            title: entry[kCGWindowName as String] as? String ?? "",
            bounds: bounds,
            isOnScreen: entry[kCGWindowIsOnscreen as String] as? Bool ?? false
        )
    }
}
