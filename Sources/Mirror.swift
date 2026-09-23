import AppKit

/// macOS only populates a display's menu bar with status items once that bar
/// has been active; until then the extra screens show system extras and no
/// app icons at all, so the fold marker is unreachable there. Draw a clone on
/// exactly those bars — never on one that already carries the real item, which
/// would read as a duplicate — and drop it as soon as the system catches up.
@MainActor
final class StatusMirror {
    var click: (() -> Void)?
    var rightClick: (() -> Void)?
    var enabled = true { didSet { guard enabled != oldValue else { return }; enabled ? refresh(probe: true) : teardown() } }
    private let ownBundle: String
    private var panels: [CGDirectDisplayID: NSPanel] = [:]
    private var insets: [CGDirectDisplayID: CGFloat] = [:]
    private var image: NSImage?
    private var toolTip: String?
    private var probing = false
    private var poll: Task<Void, Never>?
    private let width: CGFloat = 28

    init(ownBundle: String) {
        self.ownBundle = ownBundle
    }

    /// Adopt the status button's current artwork. Geometry is left untouched:
    /// a style or fold change does not move the other bars' items.
    func update(image: NSImage?, toolTip: String?) {
        self.image = image
        self.toolTip = toolTip
        for panel in panels.values {
            (panel.contentView as? MirrorView)?.image = image
            panel.contentView?.toolTip = toolTip
        }
        refresh()
    }

    /// Re-place the clones. `probe` first re-reads which bars are missing the
    /// real item and where their system items sit, which needs accessibility.
    func refresh(probe: Bool = false) {
        guard enabled, NSScreen.screens.count > 1 else { teardown(); return }
        schedulePoll()
        if probe { self.probe() }
        for screen in NSScreen.screens {
            guard let id = Self.displayID(screen) else { continue }
            guard let inset = insets[id], let frame = Self.slot(screen, width: width, inset: inset) else {
                panels[id]?.orderOut(nil)
                continue
            }
            let panel = panels[id] ?? make(id: id)
            panel.setFrame(frame, display: true)
            panel.orderFrontRegardless()
        }
        for (id, panel) in panels where !NSScreen.screens.contains(where: { Self.displayID($0) == id }) {
            panel.orderOut(nil)
            panels[id] = nil
        }
    }

    func teardown() {
        poll?.cancel(); poll = nil
        for panel in panels.values { panel.orderOut(nil) }
        panels.removeAll()
        insets.removeAll()
    }

    /// The system can populate a bar at any time, with no notification to
    /// observe. Re-read at a slow cadence so a clone never outlives the real
    /// item for long, and stop as soon as one display is left.
    private func schedulePoll() {
        guard poll == nil else { return }
        poll = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(10)) } catch { return }
                guard let self, self.enabled, NSScreen.screens.count > 1 else { return }
                self.refresh(probe: true)
            }
        }
    }

    private func make(id: CGDirectDisplayID) -> NSPanel {
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)))
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
        let view = MirrorView()
        view.image = image
        view.toolTip = toolTip
        view.click = { [weak self] in self?.click?() }
        view.rightClick = { [weak self] in self?.rightClick?() }
        panel.contentView = view
        panels[id] = panel
        return panel
    }

    private func probe() {
        guard !probing, AXIsProcessTrusted() else { return }
        probing = true
        let screens = NSScreen.screens
        guard let top = screens.first?.frame.maxY else { probing = false; return }
        // AX frames are top-left global; a bar belongs to the screen whose top
        // edge it starts at.
        let bars = screens.compactMap { screen in
            Self.displayID(screen).map {
                MirrorPlan.Bar(id: $0, top: top - screen.frame.maxY, minX: screen.frame.minX, maxX: screen.frame.maxX)
            }
        }
        Task { [weak self] in
            let snapshot = await Task.detached { MenuSnapshot.read() }.value
            guard let self else { return }
            defer { self.probing = false }
            guard snapshot.error == nil, !snapshot.items.isEmpty else { return }
            let plan = MirrorPlan.clones(items: snapshot.items, bars: bars, own: self.ownBundle)
            guard plan != self.insets else { return }
            self.insets = plan
            self.refresh()
        }
    }

    private static func displayID(_ screen: NSScreen) -> CGDirectDisplayID? {
        screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }

    /// The menu bar strip of a screen, or nil while that bar is hidden (a
    /// full-screen window, or auto-hide), where a clone must not float.
    private static func slot(_ screen: NSScreen, width: CGFloat, inset: CGFloat) -> NSRect? {
        let height = screen.frame.maxY - screen.visibleFrame.maxY
        guard height > 1 else { return nil }
        // `inset` measures the right edge of the bar to the marker's left edge.
        let x = screen.frame.maxX - inset
        guard x > screen.frame.minX, x + width < screen.frame.maxX else { return nil }
        return NSRect(x: x, y: screen.frame.maxY - height, width: width, height: height)
    }
}

private final class MirrorView: NSView {
    var image: NSImage? { didSet { needsDisplay = true } }
    var click: (() -> Void)?
    var rightClick: (() -> Void)?
    private var pressed = false { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        if pressed {
            NSColor.labelColor.withAlphaComponent(0.15).setFill()
            NSBezierPath(roundedRect: bounds.insetBy(dx: 0, dy: 3), xRadius: 5, yRadius: 5).fill()
        }
        guard let image else { return }
        let rect = NSRect(x: (bounds.width - image.size.width) / 2,
                          y: (bounds.height - image.size.height) / 2,
                          width: image.size.width, height: image.size.height)
        // Template images only tint inside a status button; do it by hand.
        let tinted = NSImage(size: image.size, flipped: false) { area in
            image.draw(in: area)
            NSColor.labelColor.set()
            area.fill(using: .sourceAtop)
            return true
        }
        tinted.draw(in: rect)
    }
    override func mouseDown(with event: NSEvent) { pressed = true }
    override func mouseUp(with event: NSEvent) {
        pressed = false
        if event.modifierFlags.contains(.control) { rightClick?() } else { click?() }
    }
    override func rightMouseDown(with event: NSEvent) { pressed = true }
    override func rightMouseUp(with event: NSEvent) { pressed = false; rightClick?() }
    override func viewDidChangeEffectiveAppearance() { needsDisplay = true }
}
