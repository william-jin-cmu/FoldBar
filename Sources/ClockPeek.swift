import AppKit
import ApplicationServices

/// While folded, macOS 27 suppresses the clock's Notification Center: the
/// click lands but nothing opens. Notification Center that is already open
/// survives a fold, though, so a clock click is served by revealing, pressing
/// the clock through accessibility, and folding again once the panel is up.
enum ClockPeek {
    /// The panel is only on screen (layer above normal windows) while open;
    /// desktop widgets from the same process sit far below normal windows.
    static func notificationCenterOpen() -> Bool {
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        let pids = Set(NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.notificationcenterui").map(\.processIdentifier))
        return windows.contains {
            guard let pid = $0[kCGWindowOwnerPID as String] as? pid_t, pids.contains(pid) else { return false }
            return ($0[kCGWindowLayer as String] as? Int ?? 0) > 0
        }
    }

    /// Press the clock nearest to `point` (top-left screen coordinates).
    static func press(near point: CGPoint) -> Bool {
        guard let agent = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.MenuBarAgent").first else { return false }
        let root = AXUIElementCreateApplication(agent.processIdentifier)
        AXUIElementSetMessagingTimeout(root, 0.25)
        var clocks: [(AXUIElement, CGRect)] = []
        func walk(_ element: AXUIElement, depth: Int) {
            if attribute(element, kAXIdentifierAttribute) as? String == "com.apple.menuextra.clock", let frame = frame(element) {
                clocks.append((element, frame)); return
            }
            guard depth < 5 else { return }
            for child in attribute(element, kAXChildrenAttribute) as? [AXUIElement] ?? [] { walk(child, depth: depth + 1) }
        }
        walk(root, depth: 0)
        guard let clock = clocks.min(by: { distance($0.1, point) < distance($1.1, point) }), distance(clock.1, point) < 40 else { return false }
        return AXUIElementPerformAction(clock.0, kAXPressAction as CFString) == .success
    }

    private static func distance(_ rect: CGRect, _ point: CGPoint) -> CGFloat {
        hypot(max(rect.minX - point.x, 0, point.x - rect.maxX), max(rect.minY - point.y, 0, point.y - rect.maxY))
    }
    private static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        AXUIElementSetMessagingTimeout(element, 0.15)
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &result) == .success else { return nil }
        return result
    }
    private static func frame(_ element: AXUIElement) -> CGRect? {
        guard let value = attribute(element, "AXFrame"), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        var rect = CGRect.zero
        guard AXValueGetValue(value as! AXValue, .cgRect, &rect) else { return nil }
        return rect
    }
}
