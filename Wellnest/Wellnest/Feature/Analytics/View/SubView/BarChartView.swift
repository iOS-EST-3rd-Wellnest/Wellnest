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
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                let maxValue = data.max() ?? 1
                let normalizedHeight = CGFloat(value / maxValue) * 60

                Rectangle()
                    .fill(color)
                    .frame(width: 20, height: normalizedHeight)
                    .cornerRadius(4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
