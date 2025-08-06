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
    let columns: Int
    let spacing: CGFloat

    init(columns: Int = 7, spacing: CGFloat = 4) {
        self.columns = columns
        self.spacing = spacing
    }

    func makeCache(subviews: Subviews) -> CalendarLayoutCache {
        CalendarLayoutCache(count: subviews.count)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CalendarLayoutCache) -> CGSize {
        let width = proposal.width ?? 0
//        let rows = Int(ceil(Double(subviews.count) / Double(columns)))
//        let itemWidth = width / CGFloat(columns)
//        let itemHeight = itemWidth
//        let height = itemHeight * CGFloat(rows)
        let height = proposal.height ?? width

        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CalendarLayoutCache) {
        let width = bounds.width
        let height = bounds.height
        let rows = Int(ceil(Double(subviews.count) / Double(columns)))

        let totalSpacingWidth = spacing * CGFloat(columns - 1)
		let totalSpacingHeight = spacing * CGFloat(rows - 1)

        let itemWidth = (width - totalSpacingWidth) / CGFloat(columns)
//        let itemHeight = itemWidth
        let itemHeight = (height - totalSpacingHeight) / CGFloat(rows)

        for index in subviews.indices {
            let row = index / columns
            let col = index % columns

            let x = bounds.minX + CGFloat(col) * (itemWidth + spacing)
            let y = bounds.minY + CGFloat(row) * (itemHeight + spacing)

            let center = CGPoint(x: x + itemWidth / 2, y: y + itemHeight / 2)

            subviews[index].place(at: center, anchor: .center, proposal: ProposedViewSize(width: itemWidth, height: itemHeight))
        }
    }
}
