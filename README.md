<p align="center">
  <img src="Assets/FoldBar-logo-v2.png" width="112" alt="FoldBar icon">
</p>
<h1 align="center">FoldBar</h1>
<p align="center"><strong>A simple menu bar manager built for macOS 27.</strong><br>Left side folds away. Right side stays visible.</p>
<p align="center">
  <a href="https://github.com/william-jin-cmu/FoldBar/releases/latest">Download</a> ·
  <a href="#how-it-works">How it works</a> ·
  <a href="#macos-27-compatibility">Compatibility</a> ·
  <a href="README.zh-CN.md">简体中文</a>
</p>
<p align="center">
  <img src="https://img.shields.io/badge/macOS-27-black" alt="macOS 27">
  <img src="https://img.shields.io/badge/Apple_Silicon-arm64-black" alt="Apple Silicon">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0--or--later-blue" alt="GPL-3.0-or-later"></a>
</p>

![FoldBar folding and revealing menu bar icons on macOS 27](Assets/demo.gif)

## Download

Get **FoldBar-0.2.8-arm64.dmg** from the [latest release](https://github.com/william-jin-cmu/FoldBar/releases/latest). A ZIP is also available. Official release packages are **Developer ID signed and Apple-notarized**, with stapled tickets for offline verification.

1. Open the DMG and drag **FoldBar** into **Applications**.
2. Quit any other menu bar manager, then open FoldBar from Applications.
3. Allow FoldBar in **System Settings → Privacy & Security → Accessibility**.

**Requires macOS 27 and Apple Silicon.** The settings interface is currently in Simplified Chinese. Release assets include signing/notarization verification details and SHA-256 checksums. There is no in-app updater yet; download future versions from Releases.

## How it works

Hold **⌘ Command** and drag an icon to either side of the FoldBar marker:

| Position | When folded |
| --- | --- |
| Left of the marker | Hidden |
| Right of the marker | Visible |

Click the marker to fold or reveal the left side. Move the marker itself with **⌘-drag** to change the boundary. Supported system items, including **battery and input source**, follow the same rule.

Right-click the marker for settings or **Restore all icons**. The optional global shortcut is **⌥⌘B**. In settings, **⌘W** closes the window while FoldBar keeps running.

## Features

- **Built for macOS 27** using its menu bar infrastructure.
- **Direct arrangement** with the standard macOS ⌘-drag gesture.
- **One rule for app and supported system icons**, based on their position.
- **Six marker styles**, including arrows and dots, in three sizes.
- **Optional auto-hide** after 5, 10, or 30 seconds, plus launch at login and fold on launch.
- **Restore on wake, display changes, or app launch**, so newly added icons remain accessible.
- **Native Swift, AppKit, and SwiftUI**, with no third-party runtime dependencies.
- **Local operation**: no account, analytics, telemetry, or screen-recording permission.

## macOS 27 compatibility

FoldBar is an early release, tested on **macOS 27.0 (26A428), Apple Silicon**. It uses a private macOS interface that may change between OS builds. It does not support macOS 26 or Intel Macs.

- **Install in Applications.** macOS may hide FoldBar's own marker if it runs from a temporary or build directory. FoldBar checks its installation location before folding.
- **Some system items stay visible**, including the clock and Control Center. The OS may suppress other extras, such as Now Playing, while folded, and clock/Notification Center interactions can be affected. Expanding restores normal behavior.
- **Multiple icons from one app are managed together.** If that app has icons on both sides, FoldBar keeps the app visible.
- **The notch and available menu bar width still apply.** There is no separate floating icon tray.
- **Multi-display behavior is not exhaustively tested.** Display changes intentionally reveal all icons.
- Auto-hide starts after a manual reveal. Opening settings or a recovery event cancels the timer.

If something goes wrong, right-click → **全部展开 / 恢复** (Restore all), or reopen FoldBar from Applications. Please [report an issue](https://github.com/william-jin-cmu/FoldBar/issues) with your macOS build and display arrangement.

## Build from source

Requires a Mac with Xcode and its command-line tools selected. The app is built for arm64; behavioral tests need macOS 27.

```sh
git clone https://github.com/william-jin-cmu/FoldBar.git
cd FoldBar
./test.sh
./build.sh
```

The default build is ad-hoc signed. Copy `build/FoldBar.app` into `/Applications` before running it. Building with a different signature may require regranting Accessibility permission.

See [Contributing](CONTRIBUTING.md) for the code map and testing, and [Releasing](docs/RELEASING.md) for Developer ID signing, notarization, and packaging.

## Credits & license

Inspired by the straightforward interaction of [Hidden Bar](https://github.com/dwarvesf/hidden) and the menu bar work in [Thaw](https://github.com/thaw-app/Thaw). The macOS 27 implementation draws on [Pelmet](https://github.com/fif7y/pelmet)'s public API research. See [References](REFERENCES.md) and [Notice](NOTICE) for attribution.

[GPL-3.0-or-later](LICENSE). Copyright © 2026 William Jin and contributors.
