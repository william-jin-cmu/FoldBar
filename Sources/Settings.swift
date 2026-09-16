import AppKit
import SwiftUI

@MainActor
struct SettingsView: View {
    @ObservedObject var preferences: Preferences
    var toggle: () -> Void
    var restore: () -> Void
    var permission: () -> Void
    @State private var page = "通用"
    @State private var previewCollapsed = false
    private let accent = Color(red: 0.91, green: 0.36, blue: 0.10)
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 10) {
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSApp.applicationIconImage).resizable().frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("FoldBar").font(.headline)
                        Text("菜单栏，收放自如").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                }.padding(.top, 24)
                VStack(spacing: 6) {
                    ForEach([("通用", "slider.horizontal.3"), ("外观", "paintbrush"), ("关于", "info.circle")], id: \.0) { name, icon in
                        Button { page = name } label: {
                            Label(name, systemImage: icon)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .background(page == name ? accent.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: 8))
                                .contentShape(Rectangle())
                        }.buttonStyle(.plain).foregroundStyle(page == name ? accent : .primary)
                    }
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(preferences.accessibility ? Color.green : Color.orange).frame(width: 6, height: 6)
                    Text(preferences.accessibility ? "已就绪" : "需要辅助功能权限").font(.caption).foregroundStyle(.secondary)
                }
                Text("0.2.8 · macOS 27").font(.caption2).foregroundStyle(.tertiary)
            }.padding(18).frame(width: 174).background(.quaternary.opacity(0.45))
            Divider()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(page).font(.system(size: 24, weight: .semibold))
                        Text(page == "通用" ? "左边收起，右边常驻。就这么简单。" : page == "外观" ? "选一个属于你的菜单栏标记。" : "给菜单栏留一点呼吸的空间。")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    Spacer()
                }.padding(26)
                if let message = preferences.message {
                    HStack(alignment: .top) {
                        Image(systemName: "info.circle").foregroundStyle(accent)
                        Text(message).font(.callout).textSelection(.enabled)
                        Spacer()
                        Button { preferences.message = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
                    }.padding(12).background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10)).padding(.horizontal, 26).padding(.bottom, 8)
                }
                Group {
                    switch page { case "外观": appearance; case "关于": about; default: general }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }.frame(width: 760, height: 620).tint(accent)
        .onAppear { preferences.refresh() }
    }
    private var general: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(preferences.busy ? "正在整理菜单栏…" : preferences.collapsed ? "左侧已收起" : "全部展开")
                        Text(preferences.collapsed ? "已收起 \(preferences.count) 组图标" : "按住 ⌘ 拖动图标或分界标记来调整左右位置")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(preferences.collapsed ? "展开" : "收起左侧", action: toggle).disabled(preferences.busy)
                }
            } header: { Text("菜单栏") }
            Section("启动") {
                Toggle("登录时启动 FoldBar", isOn: Binding(get: { preferences.loginEnabled }, set: { preferences.setLogin($0) }))
                Toggle("启动后收起左侧图标", isOn: $preferences.collapseOnLaunch)
            }
            Section("交互") {
                Picker("手动展开后自动收起", selection: $preferences.autoHide) {
                    Text("不自动收起").tag(0)
                    Text("5 秒后").tag(5)
                    Text("10 秒后").tag(10)
                    Text("30 秒后").tag(30)
                }
                Toggle(isOn: $preferences.shortcut) {
                    HStack { Text("快捷键展开 / 收起"); Spacer(); Text("⌥ ⌘ B").foregroundStyle(.secondary) }
                }
                if preferences.shortcut && !preferences.shortcutRegistered {
                    Text("快捷键未注册，可能与其他应用冲突。").font(.caption).foregroundStyle(.orange)
                }
            }
            Section("权限与恢复") {
                HStack {
                    Label(preferences.accessibility ? "辅助功能已允许" : "辅助功能未允许", systemImage: preferences.accessibility ? "checkmark.circle.fill" : "exclamationmark.circle")
                    Spacer()
                    Button("打开系统设置…", action: permission)
                }
                HStack {
                    Text("遇到问题时，恢复全部图标")
                    Spacer()
                    Button("全部展开", action: restore)
                }
            }
            Text("电池、输入法和应用图标都按分界左右处理。唤醒、连接屏幕或新应用启动时会先展开，避免遗漏新图标。")
                .font(.caption).foregroundStyle(.secondary)
        }.formStyle(.grouped)
    }
    private var appearance: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 14) {
                    HStack(spacing: 19) {
                        Group { Image(systemName: "tray"); Image(systemName: "bolt.horizontal"); Image(systemName: "battery.100") }.opacity(previewCollapsed ? 0.12 : 0.8)
                        Button { withAnimation(.easeInOut(duration: 0.2)) { previewCollapsed.toggle() } } label: {
                            Image(systemName: preferences.style.symbol(collapsed: previewCollapsed)).font(.system(size: preferences.size, weight: .medium)).frame(width: 28, height: 28)
                        }.buttonStyle(.plain).foregroundStyle(accent)
                        Image(systemName: "wifi")
                        Image(systemName: "switch.2")
                        Text("16:30").font(.system(size: 12, weight: .medium, design: .monospaced))
                    }.frame(maxWidth: .infinity).padding(18).background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 13))
                    Text("点按中间标记，预览展开与收起的样式").font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("菜单栏图标").font(.headline)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(ControlStyle.allCases) { style in
                            Button { preferences.style = style } label: {
                                VStack(spacing: 10) {
                                    HStack(spacing: 12) {
                                        Image(systemName: style.symbol(collapsed: false))
                                        Image(systemName: style.symbol(collapsed: true))
                                    }.font(.system(size: 17, weight: .medium)).frame(height: 24)
                                    Text(style.title).font(.callout)
                                }.frame(maxWidth: .infinity).padding(.vertical, 15)
                                    .background(preferences.style == style ? accent.opacity(0.1) : Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(preferences.style == style ? accent : Color.primary.opacity(0.08), lineWidth: 1))
                            }.buttonStyle(.plain).accessibilityLabel(style.title)
                        }
                    }
                }
                HStack {
                    Text("图标大小").font(.headline)
                    Spacer()
                    Picker("图标大小", selection: $preferences.size) {
                        Text("小").tag(12.0); Text("标准").tag(14.0); Text("大").tag(16.0)
                    }.labelsHidden().pickerStyle(.segmented).frame(width: 230)
                }
                Text("左侧是展开样式，右侧是收起样式。选择后立即应用，分界标记始终保留在菜单栏。")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(.horizontal, 26).padding(.bottom, 26)
        }
    }
    private var about: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSApp.applicationIconImage).resizable().frame(width: 110, height: 110)
            Text("FoldBar").font(.system(size: 28, weight: .semibold))
            Text("Less on the bar. More room to focus.").font(.callout).foregroundStyle(.secondary)
            Text("版本 0.2.8 · 为 macOS 27 制作").font(.caption).foregroundStyle(.secondary)
            Divider().padding(.vertical, 10)
            VStack(alignment: .leading, spacing: 12) {
                Label("按住 ⌘ 拖动：左边收起，右边常驻", systemImage: "cursorarrow.motionlines")
                Label("同一应用的多个图标跨在两侧时，优先保持可见", systemImage: "square.stack")
                Label("本地运行，无账号、无遥测", systemImage: "lock")
            }.font(.callout).frame(maxWidth: .infinity, alignment: .leading)
            Text("使用 macOS 27 的菜单栏接口。部分受系统保护的项目无法隐藏；系统升级后可能需要适配。隐藏期间系统附加项和时钟交互可能受影响，展开即可解除限制。")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack { Link("实现参考", destination: URL(string: "https://github.com/fif7y/pelmet")!); Text("·"); Text("GPL-3.0-or-later") }.font(.caption).foregroundStyle(.secondary)
            Spacer()
        }.padding(.horizontal, 32).padding(.top, 4)
    }
}

@MainActor
final class SettingsWindow {
    private var window: NSWindow?
    func show(preferences: Preferences, toggle: @escaping () -> Void, restore: @escaping () -> Void, permission: @escaping () -> Void) {
        if window == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 760, height: 620), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "FoldBar 设置"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView(preferences: preferences, toggle: toggle, restore: restore, permission: permission))
            window.center()
            self.window = window
        }
        preferences.refresh()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
    var isVisible: Bool { window?.isVisible == true }
}
