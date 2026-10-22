import AppKit

/// A full-screen space hides the menu bar and slides it back on any change to
/// the bar. Anything FoldBar does there (folding, revealing, floating a clone)
/// pins the bar open, so callers hold off while one is up.
enum FullScreen {
    /// Display IDs whose screen is covered edge to edge by a normal window.
    static func screens() -> Set<CGDirectDisplayID> {
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        let own = ProcessInfo.processInfo.processIdentifier
        let covered: [CGRect] = windows.compactMap {
            guard ($0[kCGWindowLayer as String] as? Int ?? -1) == 0,
                  ($0[kCGWindowOwnerPID as String] as? pid_t) != own,
                  let dict = $0[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: dict) else { return nil }
            return bounds
        }
        guard let top = NSScreen.screens.first?.frame.maxY else { return [] }
        var result = Set<CGDirectDisplayID>()
        for screen in NSScreen.screens {
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { continue }
            // CG window bounds are top-left global.
            let frame = CGRect(x: screen.frame.minX, y: top - screen.frame.maxY, width: screen.frame.width, height: screen.frame.height)
            if covered.contains(where: { $0.insetBy(dx: 1, dy: 1).contains(frame.insetBy(dx: 2, dy: 2)) && frame.insetBy(dx: -2, dy: -2).contains($0) }) {
                result.insert(id)
            }
        }
        return result
    }

    static var any: Bool { !screens().isEmpty }

    /// Which displays exist and where; a full-screen transition leaves it
    /// unchanged even when the system posts a screen-parameters change.
    static func layout() -> [String] {
        NSScreen.screens.map {
            let id = $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            return "\(id):\(NSStringFromRect($0.frame))"
        }
    }
}
