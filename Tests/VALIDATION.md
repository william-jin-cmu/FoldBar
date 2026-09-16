# 0.2.0 validation · 2026-09-16

Machine: macOS 27.0 (26A428), Apple Silicon. Final signed app installed at /Applications/FoldBar.app.

20 boundary / unified visibility checks passed.

```text
control visible under assertion: true
activation completed: true, error: none
local.jinqiu.FoldBarFixture: before=true, hidden=true, restored=true
system:0: before=true, hidden=true, restored=true
system:4: before=true, hidden=true, restored=true
PASS: live hide / restore + persistent control
STYLE chevron: collapsed=true, hiddenGroups=1, controlVisible=true, passed=true
STYLE arrow: collapsed=true, hiddenGroups=1, controlVisible=true, passed=true
STYLE dot: collapsed=true, hiddenGroups=1, controlVisible=true, passed=true
STYLE ellipsis: collapsed=true, hiddenGroups=1, controlVisible=true, passed=true
STYLE panel: collapsed=true, hiddenGroups=1, controlVisible=true, passed=true
STYLE fold: collapsed=true, hiddenGroups=1, controlVisible=true, passed=true
PASS: controller hide/reveal, all six styles, control remains visible
```

The controller test requires a nonempty hidden group and a live assertion, avoiding vacuous success. The temporary-location disappearance was reproduced, and the installed app passed. Fixtures were stopped and the temporary installed fixture moved back into the build directory.

UI: general and appearance pages inspected via Computer Use screenshot and accessibility tree. Actual user CMD-drag remains a manual acceptance check; login startup and sleep/wake are not fully exercised. The GUI app requires its own Accessibility grant; CLI test authorization does not imply GUI permission.
