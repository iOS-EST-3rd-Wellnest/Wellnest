//
//  StepsChartView.swift
//  Wellnest
//
//  Created by junil on 8/11/25.
//

import SwiftUI

struct StepsChartView: View {
    @Environment(\.colorScheme) private var colorScheme
    let period: ChartSectionView.ChartPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundColor(.orange)
                Text("일간 걸음 수")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(primaryTextColor)
                Spacer()
            }

            // 간단한 선형 차트
            LineChartView(
                data: period == .week ? weeklyStepsData : monthlyStepsData,
                color: .orange
            )
            .frame(height: 80)
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }

    private var weeklyStepsData: [Double] {
        [3000, 5500, 4200, 7800, 6100, 5900, 8200]
    }

    private var monthlyStepsData: [Double] {
        [4000, 6000, 5200, 7000, 6500, 7200, 6800, 8000]
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }

    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.15) : Color(.systemGray6)
    }
}
