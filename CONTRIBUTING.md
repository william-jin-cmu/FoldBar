# Contributing

Issues and pull requests are welcome. For bugs, include your macOS version/build,
Apple Silicon model, display arrangement, and steps to reproduce. Avoid posting
private screenshots or a full diagnostic dump without reviewing its app list.

## Development

Run `./test.sh` for boundary and system-item checks, then `./build.sh` with Xcode
selected. Install `build/FoldBar.app` in `/Applications` for real menu bar tests.
Do not run two copies of FoldBar or multiple menu bar managers together.

The app requires macOS 27 / arm64. Pure boundary tests can run on macOS 14+.

| File | Responsibility |
| --- | --- |
| `Sources/main.swift` | Lifecycle, interaction, cancellation, hide/reveal controller |
| `Sources/Boundary.swift` | Left/right classification and visibility allowlists |
| `Sources/MenuSnapshot.swift` | Read menu bar positions through Accessibility |
| `Sources/Bridge.m` | Runtime checks and private macOS 27 API bridge |
| `Sources/Settings.swift` | Native settings window |
| `Sources/Preferences.swift` | Preferences and runtime status |

Keep hide/reveal failures recoverable and preserve the control marker. Battery
and input source follow the same positional rule as app icons. Avoid per-app
special-case UI, simulated dragging, or changes to system menu bar preferences.

Developer-only commands (run the installed executable) include `--diagnose`
(read-only), `--rapid-test`, and `--integration-test` (cycle real hidden items).
The latter tests change menu bar visibility, require hideable items left of the
marker, and exit when complete. Never run them as part of normal app startup.
Historical validation notes in `Tests/` describe particular versions, not a
claim that every OS build or display arrangement has been tested.

Release instructions: [docs/RELEASING.md](docs/RELEASING.md).

Contributions are distributed under GPL-3.0-or-later.
