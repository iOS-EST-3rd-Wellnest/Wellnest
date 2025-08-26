//
//  BarChartView.swift
//  Wellnest
//
//  Created by junil on 8/11/25.
//

import SwiftUI

struct BarChartView: View {
    let data: [Double]
    let color: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.content) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                let maxValue = data.max() ?? 1
                let safeMaxValue = maxValue > 0 ? maxValue : 1 // 0보다 작거나 같으면 1로 설정
                let safeValue = max(value, 0) // 음수 방지
                let normalizedHeight = CGFloat(safeValue / safeMaxValue) * 150
                let finalHeight = normalizedHeight.isFinite && normalizedHeight > 0 ? normalizedHeight : 10 // 최소 높이 보장

                Rectangle()
                    .fill(color.opacity(safeValue > 0 ? 1.0 : 0.3)) // 0일 때는 투명도 적용
                    .frame(width: 30, height: finalHeight)
                    .cornerRadius(Spacing.inline)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
