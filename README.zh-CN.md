<p align="center"><img src="Assets/FoldBar-logo-v2.png" width="112" alt="FoldBar 图标"></p>
<h1 align="center">FoldBar</h1>
<p align="center"><strong>为 macOS 27 制作的简单菜单栏管理器。</strong><br>左侧收起，右侧常驻。</p>
<p align="center"><a href="https://github.com/william-jin-cmu/FoldBar/releases/latest">下载最新版</a> · <a href="README.md">English</a></p>

![FoldBar 在 macOS 27 上展开与收起菜单栏图标](Assets/demo.gif)

## 安装

从 [GitHub Releases](https://github.com/william-jin-cmu/FoldBar/releases/latest) 下载 **FoldBar-0.2.8-arm64.dmg**，也可选择 ZIP。正式安装包已完成 **Developer ID 签名与 Apple 公证**，并附带可离线验证的公证票据。

1. 打开 DMG，将 FoldBar 拖入「应用程序」。
2. 退出其他菜单栏管理器，再从「应用程序」打开 FoldBar。
3. 在「系统设置 → 隐私与安全性 → 辅助功能」中允许 FoldBar。

**需要 macOS 27 和 Apple Silicon。** 当前设置界面为简体中文。发行页附签名、公证验证信息和 SHA-256 校验值。暂不支持应用内自动更新，后续版本可从 Releases 下载。

## 使用

按住 **⌘ Command** 拖动图标或 FoldBar 分界标记：

| 图标位置 | 收起后 |
| --- | --- |
| 分界左侧 | 隐藏 |
| 分界右侧 | 保持显示 |

点击标记展开或收起。**电池、输入法等受支持的系统图标也遵循同一规则**，不需要单独设置。

右键可进入设置或「全部展开 / 恢复」。可选全局快捷键为 **⌥⌘B**；设置面板支持 **⌘W** 关闭，菜单栏程序继续运行。

## 功能

- 针对 macOS 27 菜单栏实现适配。
- 使用系统原生 ⌘-拖拽安排图标，直接按位置分组。
- 六种标记样式，包括箭头、圆点、侧栏等；三档大小。
- 可选 5 / 10 / 30 秒后自动收起、登录启动、启动时收起。
- 唤醒、显示器变化、新应用启动时恢复展开，方便访问新图标。
- 原生 Swift + AppKit + SwiftUI，无第三方运行时依赖。
- 本地运行，无账号、无遥测，不需要屏幕录制权限。

## macOS 27 兼容说明

这是早期版本，已在 **macOS 27.0 (26A428) / Apple Silicon** 上测试。底层使用 macOS 私有接口，系统更新后可能需要继续适配。不支持 macOS 26 或 Intel Mac。

- **必须从「应用程序」运行。** 从临时目录或构建目录启动，系统可能连 FoldBar 自身的标记一起隐藏，因此程序会检查安装位置。
- 时钟、控制中心等受保护项目保持常驻。隐藏期间，部分系统附加项（如正在播放）可能被系统连带隐藏，时钟打开通知中心也可能受影响；展开即可解除限制。
- 同一应用的多个图标按应用处理；如果跨在分界两侧，优先保持可见。
- 仍受刘海和原生菜单栏宽度限制，暂不提供独立浮动图标栏。
- 尚未完整验证所有多屏布局；显示器变化时会主动展开。
- 自动收起仅在手动展开后计时，打开设置或触发恢复会取消计时。

遇到问题可以右键选择「全部展开 / 恢复」，或从「应用程序」重新打开 FoldBar。欢迎在 [Issues](https://github.com/william-jin-cmu/FoldBar/issues) 中提供系统版本、build 号和显示器布局。

## 从源码构建

安装 Xcode 并选择命令行工具后运行：

```sh
git clone https://github.com/william-jin-cmu/FoldBar.git
cd FoldBar
./test.sh
./build.sh
```

默认使用 ad-hoc 签名，输出 `build/FoldBar.app`。复制到 `/Applications` 后运行；签名变化可能需要重新授予辅助功能权限。应用构建目标为 arm64，实际行为验证需要 macOS 27。

开发说明见 [CONTRIBUTING.md](CONTRIBUTING.md)，签名、公证和打包流程见 [RELEASING.md](docs/RELEASING.md)。

## 致谢与许可

交互参考 [Hidden Bar](https://github.com/dwarvesf/hidden)，菜单栏实现参考 [Thaw](https://github.com/thaw-app/Thaw) 的相关工作，macOS 27 接口研究参考 [Pelmet](https://github.com/fif7y/pelmet)。详见 [REFERENCES.md](REFERENCES.md) 和 [NOTICE](NOTICE)。

采用 [GPL-3.0-or-later](LICENSE)。Copyright © 2026 William Jin and contributors.
