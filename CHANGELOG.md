# Changelog

## Unreleased

- Fix: on a secondary display that lacks the real marker, the drawn copy kept a fixed distance from the right edge. That bar also omits other icons, so the copy landed on top of unrelated icons and made left-side items look like they were on the right. It now sits just left of that bar's leftmost icon, which is the fold boundary while folded and clear of every icon while expanded.
- Size the marker to its symbol instead of a fixed 28 pt, so it is spaced like the neighbouring icons.
- Re-place the copy shortly after each fold or reveal instead of waiting for the 10 s poll, and no longer drop a re-read requested while one is in flight.

## 0.3.0 — 2026-09-23

- Fix: after closing and reopening the lid, icons stayed expanded until the marker was clicked. Recovery made a single attempt two seconds after wake, which landed on the lock screen where the menu bar is unreadable; that failure discarded the fold intent, and nothing re-triggered it on unlock.
- Recovery is now a policy (`Recovery`, `FoldFailure`): it holds while the screen is locked, restarts on `com.apple.screenIsUnlocked`, retries transient failures (unreadable snapshot, missing marker, rejected or unverified request, timeout) on a 2/3/5/8/12 s backoff, and only reports permanent ones (install location, competing manager, missing interface or permission) or an exhausted schedule.
- A click on the visibly expanded bar during a pending recovery folds it immediately instead of silently cancelling the refold and waiting for auto-hide.
- Optional marker copies on secondary displays (macOS only places app icons on the main menu bar).
- Unit tests for the recovery policy; the rapid regression test covers lock/unlock hold, transient retry, user-failure reporting, and click semantics during recovery.

- Preserve collapsed intent through repeated system recovery events, including while settings are open.
- Keep opening settings from triggering a reveal, and preserve auto-hide timers when recovery is unnecessary.
- Treat an explicit toggle during pending recovery as a reveal and cancel the pending refold.
- Validate repeated recovery with settings open and explicit reveal cancellation in the rapid regression test.

## 0.2.9 — 2026-09-17

- Preserve the current fold state and auto-hide timer when another app launches.
- Keep recovery on wake, session activation, and display changes.

## 0.2.8 — 2026-09-16

First public release, built for macOS 27 / Apple Silicon.

- Fold icons to the left of a movable menu bar marker; keep the right side visible.
- Apply the same rule to supported system items, including battery and input source.
- Choose from six marker styles and three sizes.
- Optional global shortcut, automatic rehide, login launch, and fold on launch.
- Native settings with full-row navigation and standard window shortcuts.
- Handle rapid toggle cancellation and retry transient menu bar reads.
- Switch the control icon immediately, without rotation or fade animations.

See the README for macOS 27 compatibility limits. Historical local builds
0.1.0–0.2.7 were development iterations, not public releases.
