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
    static func clones(items: [BarItem], bars: [Bar], own: String) -> [UInt32: CGFloat] {
        guard bars.count > 1 else { return [:] }
        let rows = bars.map { bar in
            (bar: bar, items: items.filter {
                abs($0.frame.minY - bar.top) < 8 && $0.frame.width > 0 &&
                $0.frame.midX > bar.minX && $0.frame.midX < bar.maxX
            })
        }
        func inset(_ bar: Bar, _ item: BarItem) -> CGFloat { max(0, bar.maxX - item.frame.minX) }
        // Keep the copy the same distance from the right edge as the real
        // marker, so every bar shows the same boundary.
        let host = rows.first { row in row.items.contains { $0.bundle == own } }
        guard let hostInset = host.flatMap({ row in
            row.items.filter { $0.bundle == own }.map { inset(row.bar, $0) }.max()
        }) else { return [:] }
        var plan: [UInt32: CGFloat] = [:]
        for row in rows where !row.items.isEmpty && !row.items.contains(where: { $0.bundle == own }) {
            plan[row.bar.id] = hostInset
        }
        return plan
    }
}
