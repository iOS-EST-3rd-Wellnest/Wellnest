//
//  ExerciseStatChartCardView.swift
//  Wellnest
//
//  Created by junil on 8/12/25.
//

import SwiftUI

struct ExerciseStatChartCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPeriod: ChartPeriod = .week

    enum ChartPeriod: String, CaseIterable {
        case week = "1주"
        case month = "1개월"
    }

    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.large)
            .fill(colorScheme == .dark ? Color(.gray) : .white)
            .frame(minHeight: 320)
            .defaultShadow()
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: Spacing.content) {
                    // 상단 헤더
                    HStack {
                        HStack(spacing: Spacing.content) {
                            Image(systemName: "figure.walk")
                                .font(.title2)
                                .foregroundColor(.orange)

                            Text("운동")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        // 기간 선택 세그먼트
                        Picker("기간", selection: $selectedPeriod) {
                            ForEach(ChartPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 100)
                    }

                    // 스탯 섹션
                    HStack(spacing: Spacing.layout * 2) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("걸음 수")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(alignment: .bottom, spacing: Spacing.inline) {
                                Text("6,000보")
                                    .font(.title3)
                                    .fontWeight(.semibold)

                                Text("평균")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: Spacing.inline) {
                                Image(systemName: "arrow.up")
                                    .font(.caption)
                                    .foregroundColor(.green)

                                Text("+12%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("칼로리")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(alignment: .bottom, spacing: Spacing.inline) {
                                Text("450kcal")
                                    .font(.title3)
                                    .fontWeight(.semibold)

                                Text("소모")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: Spacing.inline) {
                                Image(systemName: "arrow.up")
                                    .font(.caption)
                                    .foregroundColor(.green)

                                Text("+8%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        }

                        Spacer()
                    }

                    // 차트 섹션
                    VStack(alignment: .leading, spacing: Spacing.content) {
                        Text("일간 걸음 수 변화")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        BarChartView(
                            data: selectedPeriod == .week ? weeklyStepsData : monthlyStepsData,
                            color: .orange
                        )
                        .frame(height: 140)
                    }
                }
                .padding()
            }
    }

    private var weeklyStepsData: [Double] {
        [3000, 5500, 4200, 7800, 6100, 5900, 8200]
    }

    private var monthlyStepsData: [Double] {
        [4000, 6000, 5200, 7000, 6500, 7200, 6800, 8000]
    }
}
