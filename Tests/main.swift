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
