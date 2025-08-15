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
                let normalizedHeight = CGFloat(value / maxValue) * 150
                Rectangle()
                    .fill(color)
                    .frame(width: 30, height: normalizedHeight)
                    .cornerRadius(Spacing.inline)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
