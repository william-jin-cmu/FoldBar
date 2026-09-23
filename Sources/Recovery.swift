import Foundation

/// Why a fold attempt did not end with the left side hidden.
///
/// Every failure the controller can hit is enumerated here so that the
/// retry policy, the user-facing message, and the tests all agree on which
/// failures are worth retrying. A `permanent` failure describes the
/// environment (wrong install location, another manager running, missing
/// permission); retrying it behind the user's back would only repeat the
/// same result. A transient failure describes the menu bar being mid-rebuild
/// (locked screen, MenuBarAgent reflow, a rejected or unverified request),
/// which is exactly what happens for several seconds after wake or unlock.
enum FoldFailure: Equatable, Sendable {
    case notInApplications
    case competitors([String])
    case interfaceUnavailable
    case accessibilityDenied
    case snapshot(String)
    case arrowMissing
    case requestRejected
    case notVerified
    case timedOut

    var permanent: Bool {
        switch self {
        case .notInApplications, .competitors, .interfaceUnavailable, .accessibilityDenied: return true
        case .snapshot, .arrowMissing, .requestRejected, .notVerified, .timedOut: return false
        }
    }

    /// Permanent failures open Settings so the user can fix the environment.
    var showsSettings: Bool { permanent }

    var message: String {
        switch self {
        case .notInApplications:
            return "请从「应用程序」文件夹打开 FoldBar。macOS 27 无法可靠保留临时目录中运行的菜单栏标记。"
        case .competitors(let names):
            return "请先退出 \(names.joined(separator: "、"))，避免同时管理菜单栏。"
        case .interfaceUnavailable:
            return "当前系统的菜单栏接口不可用，图标保持展开。"
        case .accessibilityDenied:
            return "请先在系统设置中允许 FoldBar 使用辅助功能。"
        case .snapshot(let error):
            return error
        case .arrowMissing:
            return "暂时没有读到分界标记，图标保持展开。请稍后再试。"
        case .requestRejected:
            return "系统没有接受隐藏请求，图标保持展开。"
        case .notVerified:
            return "菜单栏未完成收起，已安全展开。请确认从「应用程序」启动，并退出其他菜单栏管理器。"
        case .timedOut:
            return "系统响应超时，已展开图标。可以稍后再试。"
        }
    }
}

/// Who asked for the fold. A user click reports failures immediately; a
/// system-driven recovery (wake, unlock, display change, session switch)
/// keeps the user's fold intent and retries transient failures.
enum FoldOrigin: Equatable, Sendable { case user, recovery }

/// Re-fold policy after macOS tears down the hide assertion.
///
/// macOS reveals every icon on wake, unlock, and display reconfiguration.
/// FoldBar must fold again, but the menu bar is not readable for a while:
/// the lock screen hides MenuBarAgent's windows entirely, and after unlock
/// the bar rebuilds its layout over several seconds. One attempt at a fixed
/// delay fails in exactly these situations, so recovery instead waits for
/// unlock and retries with backoff until the fold verifies or the schedule
/// is exhausted.
enum Recovery {
    enum Step: Equatable, Sendable {
        /// Try again after this many seconds.
        case wait(seconds: Double)
        /// Do nothing now; the unlock notification restarts the schedule.
        case holdUntilUnlock
        /// Stop retrying and tell the user.
        case giveUp
    }

    /// Delay before each attempt. Attempt 0 runs after the first delay so
    /// the menu bar can finish its reveal reflow. About 30 s in total.
    static let backoff: [Double] = [2, 3, 5, 8, 12]

    static func step(attempt: Int, screenLocked: Bool) -> Step {
        if screenLocked { return .holdUntilUnlock }
        guard attempt >= 0, attempt < backoff.count else { return .giveUp }
        return .wait(seconds: backoff[attempt])
    }

    /// Whether a failed attempt should be retried instead of reported.
    static func retries(_ failure: FoldFailure, origin: FoldOrigin) -> Bool {
        origin == .recovery && !failure.permanent
    }

    /// Message shown when the whole schedule is exhausted.
    static let exhaustedMessage = "唤醒后多次尝试收起都没有成功，图标保持展开。点击标记可以再次收起。"
}
