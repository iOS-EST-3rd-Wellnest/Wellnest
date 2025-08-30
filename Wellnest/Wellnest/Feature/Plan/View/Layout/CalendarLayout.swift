//
//  CalendarLayout.swift
//  Wellnest
//
//  Created by 박동언 on 8/4/25.
//

import SwiftUI

struct CalendarLayoutCache {
    var count: Int = 0
}
struct CalendarLayout: Layout {
    enum Mode {
        case intrinsic
        case fixedSlots(slots: Int, aspectRatio: CGFloat? = nil)
    }

    let columns: Int
    let spacing: CGFloat
    let mode: Mode

    init(columns: Int = 7, spacing: CGFloat = 4, mode: Mode) {
        self.columns = columns
        self.spacing = spacing
        self.mode = mode
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let width = proposal.width ?? 0
        guard width > 0, !subviews.isEmpty else {
            return .init(width: proposal.width ?? 0, height: proposal.height ?? 0)
        }

        let totalSpacingW = spacing * CGFloat(columns - 1)
        let itemWidth = (width - totalSpacingW) / CGFloat(columns)

        switch mode {
        case .intrinsic:
            let rows = Int(ceil(Double(subviews.count) / Double(columns)))
            let firstRowMax = (0..<min(columns, subviews.count)).reduce(CGFloat.zero) { acc, i in
                max(acc, subviews[i].sizeThatFits(.init(width: itemWidth, height: nil)).height)
            }
            let height = firstRowMax * CGFloat(rows) + spacing * CGFloat(rows - 1)
            return .init(width: width, height: height)

        case .fixedSlots(let slots, let aspect):
            let itemHeight = (aspect ?? 1.0) * itemWidth
            let height = itemHeight * CGFloat(slots) + spacing * CGFloat(slots - 1)
            return .init(width: width, height: height)
        }
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        guard !subviews.isEmpty else { return }

        let totalSpacingW = spacing * CGFloat(columns - 1)
        let itemWidth = (bounds.width - totalSpacingW) / CGFloat(columns)
        let rows = Int(ceil(Double(subviews.count) / Double(columns)))

        let rowHeight: CGFloat = {
            switch mode {
            case .intrinsic:
                let contentH = bounds.height - spacing * CGFloat(max(0, rows - 1))
                return contentH / CGFloat(rows)
            case .fixedSlots:
                let contentH = bounds.height - spacing * CGFloat(max(0, rows - 1))
                return contentH / CGFloat(rows)
            }
        }()

        var y = bounds.minY
        var idx = 0
        for r in 0..<rows {
            var x = bounds.minX
            for _ in 0..<columns {
                guard idx < subviews.count else { break }
                subviews[idx].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: .init(width: itemWidth, height: rowHeight)
                )
                idx += 1
                x += itemWidth + spacing
            }
            y += rowHeight + (r < rows - 1 ? spacing : 0)
        }
    }
}
