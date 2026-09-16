import AppKit
import ApplicationServices
import ServiceManagement

@MainActor
final class FoldBar: NSObject, NSApplicationDelegate {
    private let ownBundle = Bundle.main.bundleIdentifier ?? "local.jinqiu.FoldBar"
    private var status: NSStatusItem!
    private var assertion: AnyObject?
    private var contextMenu: NSMenu?
    private var generation = 0
    private var observers: [NSObjectProtocol] = []
    private var removalObservation: NSKeyValueObservation?
    private var revealedAt = Date.distantPast
    private var lastArrow: CGRect?
    private var autoHideTask: Task<Void, Never>?
    private let preferences = Preferences()
    private let settings = SettingsWindow()
    private let shortcut = Shortcut()
    private var testing: Bool { CommandLine.arguments.contains("--integration-test") || CommandLine.arguments.contains("--rapid-test") }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installMainMenu()
        guard NSRunningApplication.runningApplications(withBundleIdentifier: ownBundle).count <= 1 else { NSApp.terminate(nil); return }
        status = NSStatusBar.system.statusItem(withLength: 28)
        status.autosaveName = "FoldBar.Arrow"
        status.behavior = .removalAllowed
        status.isVisible = true
        status.button?.target = self
        status.button?.action = #selector(click)
        status.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        status.button?.setAccessibilityTitle("FoldBar")
        removalObservation = status.observe(\.isVisible, options: [.new]) { [weak self] item, _ in
            guard !item.isVisible else { return }
            Task { @MainActor in
                self?.restore()
                self?.status.isVisible = true
            }
        }
        preferences.changed = { [weak self] in self?.applyPreferences() }
        shortcut.action = { [weak self] in self?.toggle() }
        applyPreferences()
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.didLaunchApplicationNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.restore() }
            })
        }
        observers.append(NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.lastArrow = nil; self?.restore() }
        })
        observers.append(NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.preferences.refresh() }
        })
        if testing {
            if CommandLine.arguments.contains("--rapid-test") { runRapidTest() } else { runIntegrationTest() }
            return
        }
        if CommandLine.arguments.contains("--settings") || !UserDefaults.standard.bool(forKey: "didShowSettingsV2") {
            UserDefaults.standard.set(true, forKey: "didShowSettingsV2")
            showSettings()
        } else if preferences.collapseOnLaunch {
            Task { try? await Task.sleep(for: .seconds(3)); collapse() }
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) { restore() }
    func applicationDidResignActive(_ notification: Notification) {
        contextMenu?.cancelTracking()
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        restore(); status.isVisible = true; showSettings(); return false
    }
    private func installMainMenu() {
        // NSHostingView in a manually created window does not install the
        // standard app menu. Native key equivalents (including Cmd-W) need it.
        let main = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "FoldBar")
        let settingsItem = NSMenuItem(title: "设置…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        appMenu.addItem(.separator())
        let quitItem = NSMenuItem(title: "退出 FoldBar", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        appMenu.addItem(quitItem)
        appItem.submenu = appMenu
        main.addItem(appItem)

        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: "窗口")
        // Resolve through the responder chain: closes the key window, not app.
        windowMenu.addItem(withTitle: "关闭窗口", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowItem.submenu = windowMenu
        main.addItem(windowItem)
        NSApp.mainMenu = main
        NSApp.windowsMenu = windowMenu
    }

    private func applyPreferences() {
        redraw()
        preferences.shortcutRegistered = shortcut.configure(enabled: preferences.shortcut)
        autoHideTask?.cancel()
    }
    private func redraw() {
        guard status != nil else { return }
        let visualCollapsed = preferences.collapsed || preferences.busy
        let name = preferences.style.symbol(collapsed: visualCollapsed)
        let image = NSImage(systemSymbolName: name, accessibilityDescription: visualCollapsed ? "展开隐藏图标" : "收起左侧图标")?
            .withSymbolConfiguration(.init(pointSize: preferences.size, weight: .medium))
        image?.isTemplate = true
        status.button?.image = image
        status.button?.toolTip = preferences.message ?? (preferences.busy ? "正在整理菜单栏…" : preferences.collapsed ? "点击展开 · 右键设置 · ⌥⌘B" : "⌘ 拖拽：左侧收起，右侧常驻 · 右键设置")
    }
    @objc private func click() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true { showMenu(); return }
        guard event?.modifierFlags.contains(.command) != true else { return }
        toggle()
    }
    @objc private func toggle() {
        if assertion != nil || preferences.collapsed || preferences.busy {
            restore()
            scheduleAutoHide()
        } else { collapse() }
    }
    private func scheduleAutoHide() {
        guard !testing, preferences.autoHide > 0 else { return }
        let delay = preferences.autoHide
        autoHideTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(delay)) } catch { return }
            guard let self else { return }
            // Do not close over an open app menu or a command-drag.
            while NSApp.currentEvent?.modifierFlags.contains(.command) == true || NSEvent.pressedMouseButtons != 0 || NSMenu.menuBarVisible() == false {
                do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
            }
            guard !Task.isCancelled, !self.settings.isVisible else { return }
            self.collapse()
        }
    }
    private func collapse() {
        guard !preferences.busy, assertion == nil else { return }
        autoHideTask?.cancel()
        let parent = Bundle.main.bundleURL.deletingLastPathComponent().path
        guard parent == "/Applications" || parent == NSHomeDirectory() + "/Applications" else {
            report("请从「应用程序」文件夹打开 FoldBar。macOS 27 无法可靠保留临时目录中运行的菜单栏标记。", show: true); return
        }
        let competitors = NSWorkspace.shared.runningApplications.filter {
            let id = ($0.bundleIdentifier ?? "").lowercased()
            return id.contains("thaw") || id.contains("bartender") || id == "com.jordanbaird.ice" || id == "com.dwarvesv.minimalbar"
        }
        guard competitors.isEmpty else { report("请先退出 \(competitors.compactMap(\.localizedName).joined(separator: "、"))，避免同时管理菜单栏。", show: true); return }
        guard FBAvailable() else { report("当前系统的菜单栏接口不可用，图标保持展开。", show: true); return }
        guard AXIsProcessTrusted() else { preferences.refresh(); report("请先在系统设置中允许 FoldBar 使用辅助功能。", show: true); return }
        preferences.message = nil; preferences.busy = true
        generation += 1
        let ticket = generation
        // Accept the click immediately. Wait for reveal reflow before measuring
        // positions; a later toggle/restore invalidates this ticket.
        let settleDelay = min(0.7, max(0, 0.7 - Date().timeIntervalSince(revealedAt)))
        let pointer = NSEvent.mouseLocation
        let top = NSScreen.screens.first?.frame.maxY ?? 0
        let point = CGPoint(x: pointer.x, y: top - pointer.y)
        redraw()
        Task {
            if settleDelay > 0 {
                try? await Task.sleep(for: .seconds(settleDelay))
            }
            guard ticket == generation else { return }
            var snapshot = await Task.detached { MenuSnapshot.read() }.value
            guard ticket == generation else { return }
            // The remote menu bar briefly removes its AX windows during reflow.
            for _ in 0..<3 where snapshot.error != nil || !snapshot.items.contains(where: { $0.bundle == ownBundle }) {
                try? await Task.sleep(for: .milliseconds(100))
                guard ticket == generation else { return }
                snapshot = await Task.detached { MenuSnapshot.read() }.value
                guard ticket == generation else { return }
            }
            if let error = snapshot.error { report(error); return }
            let arrows = snapshot.items.filter { $0.bundle == ownBundle }
            guard let arrow = arrows.min(by: { hypot($0.frame.midX - point.x, $0.frame.midY - point.y) < hypot($1.frame.midX - point.x, $1.frame.midY - point.y) }) else {
                report("暂时没有读到分界标记，图标保持展开。请稍后再试。"); return
            }
            lastArrow = arrow.frame
            let screen = NSScreen.screens.map { CGRect(x: $0.frame.minX, y: top - $0.frame.maxY, width: $0.frame.width, height: $0.frame.height) }
                .first { $0.contains(CGPoint(x: arrow.frame.midX, y: arrow.frame.midY)) }
            let targets = Boundary.hidden(items: snapshot.items, arrow: arrow.frame, ownBundle: ownBundle, screen: screen)
            preferences.count = targets.count
            // Empty left side is still a valid collapsed state, not an error.
            guard !targets.isEmpty else { preferences.busy = false; preferences.collapsed = true; redraw(); return }
            let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
            let allowed = VisibilityPlan.allowedBundles(running: running, items: snapshot.items, hidden: targets, own: ownBundle)
            let system = VisibilityPlan.allowedSystem(hidden: targets).map { NSNumber(value: $0) }
            let handle = FBHide(allowed.sorted(), system) { [weak self] error in
                let message = error?.localizedDescription
                Task { @MainActor in
                    guard let self, ticket == self.generation else { return }
                    if let message { self.report(message) } else { self.verify(ticket: ticket, targets: targets) }
                }
            }
            guard let handle else { report("系统没有接受隐藏请求，图标保持展开。"); return }
            assertion = handle as AnyObject
            preferences.collapsed = true
            redraw()
            Task {
                try? await Task.sleep(for: .seconds(6))
                guard ticket == generation, preferences.busy else { return }
                report("系统响应超时，已展开图标。可以稍后再试。")
            }
        }
    }
    private func verify(ticket: Int, targets: Set<String>) {
        Task {
            // MenuBarAgent rebuilds its AX tree during reflow. Retry a bounded
            // interval instead of treating one transient snapshot as failure.
            for _ in 0..<5 {
                try? await Task.sleep(for: .milliseconds(500))
                guard ticket == generation else { return }
                let snapshot = await Task.detached { MenuSnapshot.read() }.value
                guard ticket == generation else { return }
                if snapshot.error == nil,
                   snapshot.items.contains(where: { $0.bundle == ownBundle }),
                   !snapshot.items.contains(where: { targets.contains($0.key) }) {
                    preferences.busy = false; redraw(); return
                }
            }
            report("菜单栏未完成收起，已安全展开。请确认从「应用程序」启动，并退出其他菜单栏管理器。")
        }
    }
    @objc private func restore() {
        autoHideTask?.cancel(); autoHideTask = nil
        generation += 1
        if let assertion { FBRestore(assertion) }
        assertion = nil
        preferences.busy = false; preferences.collapsed = false; preferences.count = 0
        revealedAt = Date()
        redraw()
    }
    private func report(_ message: String, show: Bool = false) {
        restore(); preferences.message = message; redraw()
        NSLog("FoldBar: %@", message)
        if show && !testing { showSettings() }
    }
    @objc private func permission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    @objc private func showSettings() {
        autoHideTask?.cancel()
        settings.show(preferences: preferences, toggle: { [weak self] in self?.toggle() }, restore: { [weak self] in self?.restore() }, permission: { [weak self] in self?.permission() })
    }
    private func showMenu() {
        if let contextMenu { contextMenu.cancelTracking(); return }
        autoHideTask?.cancel()
        let menu = NSMenu()
        func add(_ title: String, _ action: Selector, key: String = "") {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: key); item.target = self; menu.addItem(item)
        }
        add(preferences.collapsed ? "展开左侧图标" : "收起左侧图标", #selector(toggle))
        add("全部展开 / 恢复", #selector(restore))
        menu.addItem(.separator())
        add("设置…", #selector(showSettings), key: ",")
        menu.addItem(.separator())
        add("退出 FoldBar", #selector(quit), key: "q")
        // macOS 27 hosts the status button in MenuBarAgent. Synthesizing a
        // second button click can leave tracking attached to the remote host.
        // Own the standard context menu directly in this process instead.
        let location = NSEvent.mouseLocation
        contextMenu = menu
        defer { contextMenu = nil }
        NSApp.activate(ignoringOtherApps: true)
        menu.popUp(positioning: nil, at: location, in: nil)
    }
    @objc private func quit() { restore(); NSApp.terminate(nil) }

    private func runRapidTest() {
        Task {
            try? await Task.sleep(for: .seconds(2))
            collapse()
            try? await Task.sleep(for: .seconds(3))
            guard assertion != nil, preferences.count > 0, !preferences.busy else {
                print("FAIL: rapid-test requires real hideable icons left of the control")
                restore(); exit(1)
            }
            var passed = true
            for delay in [0, 80, 200, 500] {
                toggle() // expand
                if delay > 0 { try? await Task.sleep(for: .milliseconds(delay)) }
                toggle() // re-collapse, inside the former 700 ms dead zone
                let accepted = preferences.busy
                let started = Date()
                while preferences.busy && Date().timeIntervalSince(started) < 7 {
                    try? await Task.sleep(for: .milliseconds(100))
                }
                let snapshot = await Task.detached { MenuSnapshot.read() }.value
                let ok = accepted && assertion != nil && preferences.collapsed && !preferences.busy &&
                    preferences.message == nil && snapshot.items.contains { $0.bundle == ownBundle }
                print("RAPID \(delay)ms (\(Int(Date().timeIntervalSince(started) * 1000))ms incl verification): accepted=\(accepted), collapsed=\(preferences.collapsed), busy=\(preferences.busy), control=\(snapshot.items.contains { $0.bundle == ownBundle }), message=\(preferences.message ?? "none"), snapshotError=\(snapshot.error ?? "none"), passed=\(ok)")
                passed = passed && ok
            }
            restore()
            collapse() // queue while reveal animation is running
            try? await Task.sleep(for: .milliseconds(50))
            toggle() // last click requests expanded; queued collapse must die
            try? await Task.sleep(for: .seconds(2))
            let cancelled = assertion == nil && !preferences.collapsed && !preferences.busy
            print("CANCEL queued collapse: passed=\(cancelled)")
            passed = passed && cancelled
            restore()
            print(passed ? "PASS: rapid toggle regression" : "FAIL: rapid toggle regression")
            exit(passed ? 0 : 1)
        }
    }

    private func runIntegrationTest() {
        Task {
            try? await Task.sleep(for: .seconds(2))
            var success = true
            let originalStyle = preferences.style
            for style in ControlStyle.allCases {
                preferences.style = style
                collapse()
                try? await Task.sleep(for: .seconds(4))
                let snapshot = await Task.detached { MenuSnapshot.read() }.value
                let visible = snapshot.items.contains { $0.bundle == ownBundle }
                let passed = assertion != nil && preferences.count > 0 && preferences.collapsed && !preferences.busy && visible && preferences.message == nil && status.button?.image != nil
                print("STYLE \(style.rawValue): collapsed=\(preferences.collapsed), hiddenGroups=\(preferences.count), controlVisible=\(visible), passed=\(passed)")
                success = success && passed
                restore()
                try? await Task.sleep(for: .seconds(1))
            }
            preferences.style = originalStyle
            print(success ? "PASS: controller hide/reveal, all six styles, control remains visible" : "FAIL: controller integration")
            restore()
            exit(success ? 0 : 1)
        }
    }
}
if CommandLine.arguments.contains("--smoke-test") {
    exit(smokeTest() ? 0 : 1)
} else if CommandLine.arguments.contains("--fixture") {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let item = NSStatusBar.system.statusItem(withLength: 26)
    item.autosaveName = "FoldBar.TestFixture"
    item.button?.title = "FB"
    item.button?.setAccessibilityTitle("FoldBar test fixture")
    withExtendedLifetime(item) { app.run() }
} else if CommandLine.arguments.contains("--diagnose") {
    print("macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
    print("MenuBarClientCore available: \(FBAvailable())")
    print("Accessibility authorized: \(AXIsProcessTrusted())")
    let snapshot = MenuSnapshot.read()
    print("Snapshot: \(snapshot.items.count) items; error: \(snapshot.error ?? "none")")
    for item in snapshot.items { print("\(item.key) \(item.frame)") }
} else {
    MainActor.assumeIsolated {
        let app = NSApplication.shared
        let delegate = FoldBar()
        app.delegate = delegate
        app.run()
    }
}
