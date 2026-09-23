import Foundation
func item(_ bundle: String, _ x: CGFloat, _ y: CGFloat = 0, system: Int? = nil) -> BarItem {
    BarItem(bundle: bundle, frame: CGRect(x: x, y: y, width: 20, height: 24), systemID: system)
}
let arrow = CGRect(x: 100, y: 0, width: 24, height: 24)
func check(_ items: [BarItem], _ expected: Set<String>) {
    let actual = Boundary.hidden(items: items, arrow: arrow, ownBundle: "foldbar")
    precondition(actual == expected, "Expected \(expected), got \(actual)")
}
check([item("left", 40), item("right", 140), item("foldbar", 100)], ["left"])
check([item("same", 40), item("same", 140)], [])
check([item("otherDisplay", 20, 100), item("left", 40)], ["left"])
check([item("com.apple.MenuBarAgent", 40, system: 0), item("com.apple.MenuBarAgent", 140, system: 2)], ["system:0"])
check([item("com.apple.TextInputMenuAgent", 40, system: 4)], ["system:4"])
check([item("foldbar", 20), item("com.apple.controlcenter", 40)], [])
check([item("left", 40), item("left", 40)], ["left"])
check([], [])
precondition(Boundary.systemID(identifier: "com.apple.menuextra.battery") == 0)
precondition(Boundary.systemID(identifier: "com.apple.menuextra.keyboard") == 4)
precondition(Boundary.systemID(identifier: "com.apple.menuextra.unknown") == nil)
let sameHeightDisplays = [item("neighbor", -80), item("local", 40)]
precondition(Boundary.hidden(items: sameHeightDisplays, arrow: arrow, ownBundle: "foldbar", screen: CGRect(x: 0, y: 0, width: 500, height: 400)) == ["local"])
print("12 boundary / system identity checks passed")
check([item("com.apple.MenuBarAgent", 140, system: 0), item("com.apple.TextInputMenuAgent", 150, system: 4)], [])
check([item("com.apple.MenuBarAgent", 20, system: 2), item("com.apple.MenuBarAgent", 40, system: 8)], [])
let systemItems = [item("com.apple.MenuBarAgent", 40, system: 0), item("com.apple.TextInputMenuAgent", 60, system: 4)]
let leftSystem = Boundary.hidden(items: systemItems, arrow: arrow, ownBundle: "foldbar")
precondition(leftSystem == ["system:0", "system:4"])
let allowed = VisibilityPlan.allowedBundles(running: ["foldbar", "visible", "hidden", "com.apple.TextInputMenuAgent"], items: systemItems, hidden: leftSystem.union(["hidden", "foldbar"]), own: "foldbar")
precondition(allowed.contains("foldbar"))
precondition(allowed.contains("visible") && !allowed.contains("hidden"))
precondition(!allowed.contains("com.apple.TextInputMenuAgent"))
precondition(VisibilityPlan.allowedSystem(hidden: leftSystem) == [1,2,3,5,6,7,8])
let shownInput = VisibilityPlan.allowedBundles(running: ["com.apple.TextInputMenuAgent"], items: systemItems, hidden: [], own: "foldbar")
precondition(shownInput.contains("com.apple.TextInputMenuAgent"))
print("8 unified visibility / protected control checks passed")

// Menu bar copies on displays the system has not populated yet.
let main = MirrorPlan.Bar(id: 1, top: 0, minX: 0, maxX: 1920)
let side = MirrorPlan.Bar(id: 2, top: 112, minX: -1728, maxX: 0)
let onMain = [item("other", 1600), item("foldbar", 1689)]
let onSide = [item("other", -400, 112), item("foldbar", -231, 112)]
// Only the populated bar carries the control: the other gets a copy at the
// same distance from its right edge.
precondition(MirrorPlan.clones(items: onMain + [item("other", -400, 112)], bars: [main, side], own: "foldbar") == [2: 231])
// Both bars already show it: no copy anywhere.
precondition(MirrorPlan.clones(items: onMain + onSide, bars: [main, side], own: "foldbar").isEmpty)
// A bar that reads as empty is left alone rather than guessed at.
precondition(MirrorPlan.clones(items: onMain, bars: [main, side], own: "foldbar").isEmpty)
// Nothing to copy while the control itself is unreadable.
precondition(MirrorPlan.clones(items: [item("other", 1600), item("other", -400, 112)], bars: [main, side], own: "foldbar").isEmpty)
// A single display never needs a copy.
precondition(MirrorPlan.clones(items: onMain, bars: [main], own: "foldbar").isEmpty)
print("5 menu bar copy placement checks passed")

// Recovery policy: hold on lock, back off while the bar settles, give up once.
precondition(Recovery.step(attempt: 0, screenLocked: true) == .holdUntilUnlock)
precondition(Recovery.step(attempt: 4, screenLocked: true) == .holdUntilUnlock)
precondition(Recovery.step(attempt: 0, screenLocked: false) == .wait(seconds: Recovery.backoff[0]))
precondition(Recovery.step(attempt: Recovery.backoff.count - 1, screenLocked: false) == .wait(seconds: Recovery.backoff.last!))
precondition(Recovery.step(attempt: Recovery.backoff.count, screenLocked: false) == .giveUp)
precondition(Recovery.step(attempt: -1, screenLocked: false) == .giveUp)
precondition(Recovery.backoff == Recovery.backoff.sorted(), "later attempts wait longer")
precondition(Recovery.backoff.reduce(0, +) <= 45, "recovery finishes within a realistic post-wake window")
// Transient failures retry only for system-driven recovery; permanent ones never do.
let transient: [FoldFailure] = [.snapshot("菜单栏暂时不可读取；请解锁屏幕后重试。"), .arrowMissing, .requestRejected, .notVerified, .timedOut]
let permanent: [FoldFailure] = [.notInApplications, .competitors(["Bartender"]), .interfaceUnavailable, .accessibilityDenied]
for failure in transient {
    precondition(!failure.permanent && !failure.showsSettings)
    precondition(Recovery.retries(failure, origin: .recovery))
    precondition(!Recovery.retries(failure, origin: .user))
}
for failure in permanent {
    precondition(failure.permanent && failure.showsSettings)
    precondition(!Recovery.retries(failure, origin: .recovery))
    precondition(!Recovery.retries(failure, origin: .user))
}
precondition(FoldFailure.competitors(["Ice", "Bartender"]).message.contains("Ice、Bartender"))
precondition(FoldFailure.snapshot("x").message == "x")
print("10 recovery policy / failure routing checks passed")
