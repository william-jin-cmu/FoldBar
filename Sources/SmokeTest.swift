import AppKit
import ApplicationServices

/// Development probe. Run from the installed app, with the test fixture
/// running and other menu-bar managers stopped. Always releases its assertion.
func smokeTest() -> Bool {
    _ = NSApplication.shared
    NSApp.setActivationPolicy(.accessory)
    let control = NSStatusBar.system.statusItem(withLength: 24)
    control.autosaveName = "FoldBar.SmokeControl"
    control.button?.title = "›"
    control.button?.setAccessibilityTitle("FoldBar Smoke Control")
    defer { NSStatusBar.system.removeStatusItem(control) }
    let own = Bundle.main.bundleIdentifier ?? "local.jinqiu.FoldBar"
    func settle() { RunLoop.current.run(until: Date().addingTimeInterval(1.5)) }
    func snapshot() -> MenuSnapshot {
        let lock = NSLock()
        var value: MenuSnapshot?
        DispatchQueue.global().async {
            let result = MenuSnapshot.read()
            lock.lock(); value = result; lock.unlock()
        }
        while true {
            lock.lock(); let result = value; lock.unlock()
            if let result { return result }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
    }
    settle()
    let before = snapshot()
    let fixture = "local.jinqiu.FoldBarFixture"
    guard before.error == nil, before.items.contains(where: { $0.bundle == fixture }) else {
        print("FAIL: fixture unavailable before test; \(before.error ?? "not running")"); return false
    }
    let targets: Set<String> = [fixture, "system:0", "system:4"]
    let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
    let allowed = VisibilityPlan.allowedBundles(running: running, items: before.items, hidden: targets, own: own)
    var activationError: String?
    var completed = false
    let handle = FBHide(allowed.sorted(), VisibilityPlan.allowedSystem(hidden: targets).map { NSNumber(value: $0) }) { error in
        DispatchQueue.main.async { activationError = error?.localizedDescription; completed = true }
    }
    guard let handle else { print("FAIL: no assertion"); return false }
    defer { FBRestore(handle) }
    settle()
    let during = snapshot()
    FBRestore(handle)
    settle()
    let after = snapshot()
    let ownVisible = during.items.contains { $0.bundle == own }
    var success = ownVisible && completed && activationError == nil && during.error == nil && after.error == nil
    print("control visible under assertion: \(ownVisible)")
    print("activation completed: \(completed), error: \(activationError ?? "none")")
    for key in targets.sorted() {
        let b = before.items.contains { $0.key == key }
        let d = during.items.contains { $0.key == key }
        let a = after.items.contains { $0.key == key }
        print("\(key): before=\(b), hidden=\(!d), restored=\(a)")
        // Missing test inputs must fail instead of producing a vacuous pass.
        success = success && b && !d && a
    }
    print(success ? "PASS: live hide / restore + persistent control" : "FAIL: live hide / restore")
    return success
}
