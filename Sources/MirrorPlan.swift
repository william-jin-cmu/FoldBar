import Foundation
import CoreGraphics

/// Which menu bars need a drawn copy of the control, and where it goes.
/// Pure geometry over one accessibility snapshot: the caller supplies one
/// `Bar` per display, in the same top-left global coordinates as the items.
enum MirrorPlan {
    struct Bar: Sendable {
        let id: UInt32
        /// Distance from the topmost bar to this bar's top edge.
        let top: CGFloat
        let minX: CGFloat
        let maxX: CGFloat
    }

    /// Returns, per display, the distance from the right edge of that bar to
    /// the left edge of the copy. A bar that already carries the control, or
    /// that reads as empty, is left alone: a stale copy beside the real item
    /// is worse than a missing one.
    ///
    /// The copy is a floating panel and cannot push icons aside, and the other
    /// bars leave out some items (the control itself among them), so a fixed
    /// distance from the right edge lands on top of unrelated icons. Instead it
    /// sits just left of the bar's leftmost item: while folded the bar only
    /// shows the right side, which puts the copy exactly on the boundary; while
    /// expanded it stays clear of every icon.
    static func clones(items: [BarItem], bars: [Bar], own: String, width: CGFloat, gap: CGFloat = 4) -> [UInt32: CGFloat] {
        guard bars.count > 1 else { return [:] }
        let rows = bars.map { bar in
            (bar: bar, items: items.filter {
                abs($0.frame.minY - bar.top) < 8 && $0.frame.width > 0 &&
                $0.frame.midX > bar.minX && $0.frame.midX < bar.maxX
            })
        }
        // Nothing to copy while the control itself is unreadable.
        guard rows.contains(where: { row in row.items.contains { $0.bundle == own } }) else { return [:] }
        var plan: [UInt32: CGFloat] = [:]
        for row in rows where !row.items.contains(where: { $0.bundle == own }) {
            guard let left = row.items.map(\.frame.minX).min() else { continue }
            plan[row.bar.id] = row.bar.maxX - left + gap + width
        }
        return plan
    }
}
