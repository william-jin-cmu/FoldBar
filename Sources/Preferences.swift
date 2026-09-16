import AppKit
import SwiftUI
import ServiceManagement
import ApplicationServices

enum ControlStyle: String, CaseIterable, Identifiable {
    case chevron, arrow, dot, ellipsis, panel, fold
    var id: String { rawValue }
    var title: String {
        switch self { case .chevron: return "折角"; case .arrow: return "箭头"; case .dot: return "圆点"; case .ellipsis: return "圆点组"; case .panel: return "侧栏"; case .fold: return "折叠" }
    }
    func symbol(collapsed: Bool) -> String {
        switch self {
        case .chevron: return collapsed ? "chevron.left" : "chevron.right"
        case .arrow: return collapsed ? "arrow.left" : "arrow.right"
        case .dot: return collapsed ? "circle.fill" : "circle"
        case .ellipsis: return collapsed ? "ellipsis" : "ellipsis.circle"
        case .panel: return collapsed ? "sidebar.left" : "rectangle"
        case .fold: return collapsed ? "chevron.left.2" : "chevron.right.2"
        }
    }
}

@MainActor
final class Preferences: ObservableObject {
    private let defaults = UserDefaults.standard
    var changed: (() -> Void)?
    @Published var style: ControlStyle { didSet { defaults.set(style.rawValue, forKey: "controlStyle"); changed?() } }
    @Published var size: Double { didSet { defaults.set(size, forKey: "controlSize"); changed?() } }
    @Published var autoHide: Int { didSet { defaults.set(autoHide, forKey: "autoHideDelay"); changed?() } }
    @Published var collapseOnLaunch: Bool { didSet { defaults.set(collapseOnLaunch, forKey: "collapseOnLaunch"); changed?() } }
    @Published var shortcut: Bool { didSet { defaults.set(shortcut, forKey: "enableShortcut"); changed?() } }
    @Published var collapsed = false
    @Published var busy = false
    @Published var count = 0
    @Published var message: String?
    @Published var accessibility = AXIsProcessTrusted()
    @Published var loginEnabled = SMAppService.mainApp.status == .enabled
    @Published var loginApproval = SMAppService.mainApp.status == .requiresApproval
    @Published var shortcutRegistered = false
    init() {
        style = ControlStyle(rawValue: UserDefaults.standard.string(forKey: "controlStyle") ?? "") ?? .chevron
        let storedSize = UserDefaults.standard.double(forKey: "controlSize")
        size = [12.0,14.0,16.0].contains(storedSize) ? storedSize : 14
        autoHide = UserDefaults.standard.integer(forKey: "autoHideDelay")
        collapseOnLaunch = UserDefaults.standard.bool(forKey: "collapseOnLaunch")
        shortcut = UserDefaults.standard.object(forKey: "enableShortcut") as? Bool ?? true
        defaults.removeObject(forKey: "hideSystem0")
        defaults.removeObject(forKey: "hideSystem4")
    }
    func refresh() {
        accessibility = AXIsProcessTrusted()
        loginEnabled = SMAppService.mainApp.status == .enabled
        loginApproval = SMAppService.mainApp.status == .requiresApproval
    }
    func setLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch { message = "登录启动未更新：\(error.localizedDescription)" }
        refresh()
        if loginApproval { SMAppService.openSystemSettingsLoginItems() }
    }
}
