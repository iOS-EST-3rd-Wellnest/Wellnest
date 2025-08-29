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
        /// 서브뷰 intrinsic 높이에 맞춰 계산(요일 헤더 등)
        case intrinsic
        /// 총 높이는 `slots`(예: 6) 기준으로 계산.
        /// 실제 rows(4/5/6)는 전체를 꽉 채우며 Top 정렬.
        /// aspectRatio: nil=정사각형, 값이면 itemHeight = itemWidth * ratio
        case fixedSlots(slots: Int, aspectRatio: CGFloat? = nil)
    }

    let columns: Int
    let spacing: CGFloat           // 가로/세로 동일 간격
    let mode: Mode

    init(columns: Int = 7, spacing: CGFloat = 4, mode: Mode) {
        self.columns = columns
        self.spacing = spacing
        self.mode = mode
    }

    // MARK: - size
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
            // 첫 행의 최대 intrinsic 높이로 행 높이 추정
            let firstRowMax = (0..<min(columns, subviews.count)).reduce(CGFloat.zero) { acc, i in
                max(acc, subviews[i].sizeThatFits(.init(width: itemWidth, height: nil)).height)
            }
            let height = firstRowMax * CGFloat(rows) + spacing * CGFloat(rows - 1)
            return .init(width: width, height: height)

        case .fixedSlots(let slots, let aspect):
            // 총 높이는 항상 slots(예: 6) 기준
            let itemHeight = (aspect ?? 1.0) * itemWidth
            let height = itemHeight * CGFloat(slots) + spacing * CGFloat(slots - 1)
            return .init(width: width, height: height)
        }
    }

    // MARK: - place
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

        // 행 높이 계산
        let rowHeight: CGFloat = {
            switch mode {
            case .intrinsic:
                // intrinsic에서도 전체를 꽉 채우며 Top 정렬
                let contentH = bounds.height - spacing * CGFloat(max(0, rows - 1))
                return contentH / CGFloat(rows)
            case .fixedSlots:
                // 총 높이는 6줄 기준으로 잡혀 있지만,
                // 실제 rows로 "전체를 꽉 채우며" Top 정렬
                let contentH = bounds.height - spacing * CGFloat(max(0, rows - 1))
                return contentH / CGFloat(rows)
            }
        }()

        // ⬇️ Top 정렬: 각 셀을 좌상단(anchor: .topLeading)에 배치
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
