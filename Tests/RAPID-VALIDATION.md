# 0.2.3 rapid-toggle regression

Executed against the installed signed app on macOS 27.0 (26A428), with a nonempty native hide assertion. The test requires accepted input, completed collapse, a visible control, and cancellation of stale queued requests.

```text
RAPID 0ms: accepted=true, collapsed=true, passed=true
RAPID 80ms: accepted=true, collapsed=true, passed=true
RAPID 200ms: accepted=true, collapsed=true, passed=true
RAPID 500ms: accepted=true, collapsed=true, passed=true
CANCEL queued collapse: passed=true
PASS: rapid toggle regression
```
