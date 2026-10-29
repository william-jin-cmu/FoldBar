import Foundation
import CoreGraphics

struct BarItem: Sendable {
    let bundle: String
    let frame: CGRect
    var systemID: Int? = nil
    var key: String { systemID.map { "system:\($0)" } ?? bundle }
}

enum Boundary {
    static func systemID(identifier: String) -> Int? {
        let mapping = ["battery": 0, "bluetooth": 1, "clock": 2, "display": 3,
                       "displays": 3, "textinput": 4, "keyboard": 4, "sound": 5,
                       "wifi": 6, "screen-mirroring": 7]
        guard identifier.hasPrefix("com.apple.menuextra.") else { return nil }
        return mapping[String(identifier.dropFirst("com.apple.menuextra.".count))]
    }
    /// Compare only items in the same physical menu bar. Apps straddling the
    /// boundary stay visible: preserving the right-hand side takes precedence.
    static func hidden(items: [BarItem], arrow: CGRect, ownBundle: String, screen: CGRect? = nil) -> Set<String> {
        let row = items.filter {
            abs($0.frame.midY - arrow.midY) < 8 && $0.frame.width > 0 &&
            (screen == nil || screen!.contains(CGPoint(x: $0.frame.midX, y: $0.frame.midY)))
        }
        let left = Set(row.filter { $0.frame.maxX <= arrow.minX + 1 }.map(\.key))
        let right = Set(row.filter { $0.frame.minX >= arrow.maxX - 1 }.map(\.key))
        return left.subtracting(right).filter {
            $0 != ownBundle && $0 != "system:2" && $0 != "system:8" && (!$0.hasPrefix("com.apple.") || $0 == "com.apple.systemuiserver")
        }
    }
}

/// A single visibility rule for every item. System identifiers only change
/// how the same left/right decision is conveyed to the OS.
enum VisibilityPlan {
    /// Only bundles seen outside the hidden side stay visible. Whatever the
    /// snapshot missed (an app that failed to answer during reflow, or one that
    /// adds its item later, which lands on the left) stays hidden, except
    /// bundles a previous fold kept visible.
    static func allowedBundles(items: [BarItem], hidden: Set<String>, own: String, remembered: Set<String> = []) -> Set<String> {
        var allowed = Set(items.map(\.bundle)).union(remembered).subtracting(hidden)
        if hidden.contains("system:4") { allowed.remove("com.apple.TextInputMenuAgent") }
        allowed.formUnion([own, "com.apple.MenuBarAgent", "com.apple.controlcenter"])
        return allowed
    }
    static func allowedSystem(hidden: Set<String>) -> [Int] {
        (0...8).filter { !hidden.contains("system:\($0)") }
    }
}
