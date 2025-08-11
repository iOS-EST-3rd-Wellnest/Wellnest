//
//  SleepChartView.swift
//  Wellnest
//
//  Created by junil on 8/11/25.
//

import SwiftUI

struct SleepChartView: View {
    @Environment(\.colorScheme) private var colorScheme
    let period: ChartSectionView.ChartPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.blue)
                Text("수면 시간")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(primaryTextColor)
                Spacer()
            }

            // 막대 차트
            BarChartView(
                data: period == .week ? weeklySleepData : monthlySleepData,
                color: .blue
            )
            .frame(height: 80)
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }

    private var weeklySleepData: [Double] {
        [6.5, 7.2, 6.8, 8.1, 7.5, 7.0, 7.8]
    }

    private var monthlySleepData: [Double] {
        [7.0, 7.5, 6.8, 7.2, 7.8, 7.1, 6.9, 7.6]
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }

    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.15) : Color(.systemGray6)
    }
}
