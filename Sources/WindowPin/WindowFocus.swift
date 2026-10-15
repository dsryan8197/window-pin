import AppKit
import ApplicationServices

/// Brings a pinned window's original back to the front.
enum WindowFocus {
    static func bringToFront(_ target: AppWindow) {
        let current = WindowCatalog.window(id: target.id) ?? target

        // With Accessibility permission, raise the exact window, not just its app.
        if Permissions.hasAccessibility {
            let appElement = AXUIElementCreateApplication(current.ownerPID)
            AXUIElementSetAttributeValue(appElement, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
            if let window = axWindow(matching: current, in: appElement) {
                AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
                AXUIElementPerformAction(window, kAXRaiseAction as CFString)
            }
        }

        let app = NSRunningApplication(processIdentifier: current.ownerPID)
        if #available(macOS 14.0, *) {
            app?.activate()
        } else {
            app?.activate(options: [.activateIgnoringOtherApps])
        }
    }

    /// The accessibility element for a window, matched by position and size, then by title.
    private static func axWindow(matching target: AppWindow, in app: AXUIElement) -> AXUIElement? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
              let values = value as? [AnyObject]
        else { return nil }
        let windows = values.compactMap { value in
            CFGetTypeID(value) == AXUIElementGetTypeID() ? (value as! AXUIElement) : nil
        }

        if let match = windows.first(where: { frame(of: $0).map { roughlyEqual($0, target.bounds) } ?? false }) {
            return match
        }
        guard !target.title.isEmpty else { return nil }
        return windows.first { title(of: $0) == target.title }
    }

    private static func frame(of window: AXUIElement) -> CGRect? {
        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let positionValue, let sizeValue,
              CFGetTypeID(positionValue) == AXValueGetTypeID(),
              CFGetTypeID(sizeValue) == AXValueGetTypeID()
        else { return nil }
        var position = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        return CGRect(origin: position, size: size)
    }

    private static func title(of window: AXUIElement) -> String? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &value) == .success else { return nil }
        return value as? String
    }

    private static func roughlyEqual(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) <= 2 && abs(a.minY - b.minY) <= 2
            && abs(a.width - b.width) <= 2 && abs(a.height - b.height) <= 2
    }
}
