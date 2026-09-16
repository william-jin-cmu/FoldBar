# 0.2.6 transition validation

Signed installed app on macOS 27.0, 2026-09-16. Boundary/visibility checks: 20 passed.

Rapid-toggle test waits for asynchronous verification (up to 7 seconds), rather than assuming every query completes within 3 seconds. Earlier fixed-3-second runs intermittently observed pending reads. Per-element AX messaging timeouts now bound those reads. Timings below include reflow settling, hiding, verification, and the final snapshot; they are not animation durations.

```text
RAPID 0ms (2032ms incl verification): accepted=true, collapsed=true, busy=false, control=true, message=none, snapshotError=none, passed=true
RAPID 80ms (1786ms incl verification): accepted=true, collapsed=true, busy=false, control=true, message=none, snapshotError=none, passed=true
RAPID 200ms (1170ms incl verification): accepted=true, collapsed=true, busy=false, control=true, message=none, snapshotError=none, passed=true
RAPID 500ms (838ms incl verification): accepted=true, collapsed=true, busy=false, control=true, message=none, snapshotError=none, passed=true
CANCEL queued collapse: passed=true
PASS: rapid toggle regression
```

Control image crossfades for 180 ms, starting when collapse is accepted; cancellation replaces the animation. Reduce Motion uses immediate updates. Visual smoothness of the remotely hosted control still needs user confirmation; system icon motion remains OS-owned.
