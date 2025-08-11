//
//  ChartSectionView.swift
//  Wellnest
//
//  Created by junil on 8/11/25.
//

import SwiftUI

struct ChartSectionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPeriod: ChartPeriod = .week

    enum ChartPeriod: String, CaseIterable {
        case week = "1주"
        case month = "1개월"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("변화")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryTextColor)

                Spacer()

                // 기간 선택 세그먼트
                Picker("기간", selection: $selectedPeriod) {
                    ForEach(ChartPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
            }

            VStack(spacing: 16) {
                // 걸음 수 차트
                StepsChartView(period: selectedPeriod)

                // 수면 시간 차트
                SleepChartView(period: selectedPeriod)
            }
        }
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
}
