import AppKit
import ApplicationServices

struct MenuSnapshot: Sendable {
    let items: [BarItem]
    let error: String?

    static func read() -> MenuSnapshot {
        guard AXIsProcessTrusted() else { return .init(items: [], error: "需要辅助功能权限才能读取图标的位置。") }
        guard let agent = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.MenuBarAgent").first else {
            return .init(items: [], error: "没有找到 macOS MenuBarAgent。")
        }
        let root = AXUIElementCreateApplication(agent.processIdentifier)
        AXUIElementSetMessagingTimeout(root, 0.25)
        let windows = children(root).filter { attribute($0, kAXRoleAttribute) as? String == "AXWindow" }
        var items: [BarItem] = []
        var seenFrames: [CGRect] = []
        for window in windows {
            for group in children(window) {
                guard let frame = frame(group), frame.width > 0,
                      !seenFrames.contains(frame) else { continue }
                // MenuBarAgent exposes duplicate window trees for the same bar.
                // Only traverse a successfully resolved on-screen group once.
                // The agent's groups embed an AXApplication or a status button
                // owned by the original process. No title matching is required.
                let groupChildren = children(group)
                var applicationBundle: String?
                for child in groupChildren {
                    var pid: pid_t = 0
                    AXUIElementGetPid(child, &pid)
                    if pid > 0, pid != agent.processIdentifier,
                       let bundle = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier {
                        applicationBundle = bundle
                        break
                    }
                }
                if let bundle = applicationBundle {
                    items.append(BarItem(bundle: bundle, frame: frame, systemID: bundle == "com.apple.TextInputMenuAgent" ? 4 : nil))
                    seenFrames.append(frame)
                    continue
                }
                let leaves = groupChildren + groupChildren.flatMap { children($0) }
                if let systemID = leaves.compactMap({ element -> Int? in
                    guard let identifier = attribute(element, kAXIdentifierAttribute) as? String else { return nil }
                    return Boundary.systemID(identifier: identifier)
                }).first {
                    items.append(BarItem(bundle: "com.apple.MenuBarAgent", frame: frame, systemID: systemID))
                    seenFrames.append(frame)
                    continue
                }

            }
        }
        return .init(items: items, error: windows.isEmpty ? "菜单栏暂时不可读取；请解锁屏幕后重试。" : nil)
    }

    private static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        AXUIElementSetMessagingTimeout(element, 0.15)
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &result) == .success else { return nil }
        return result
    }
    private static func children(_ element: AXUIElement) -> [AXUIElement] {
        attribute(element, kAXChildrenAttribute) as? [AXUIElement] ?? []
    }
    private static func frame(_ element: AXUIElement) -> CGRect? {
        guard let value = attribute(element, "AXFrame"), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        var rect = CGRect.zero
        guard AXValueGetValue(value as! AXValue, .cgRect, &rect) else { return nil }
        return rect
    }
}
