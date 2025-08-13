//
//  SleepStatChartCardView.swift
//  Wellnest
//
//  Created by junil on 8/12/25.
//

import SwiftUI

struct SleepStatChartCardView: View {
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
                            Image(systemName: "bed.double.fill")
                                .font(.title2)
                                .foregroundColor(.blue)

                            Text("수면")
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
                            Text("수면 시간")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(alignment: .bottom, spacing: Spacing.inline) {
                                Text("7시간 15분")
                                    .font(.title3)
                                    .fontWeight(.semibold)

                                Text("평균")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: Spacing.inline) {
                                Image(systemName: "minus")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Text("유지")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("수면 질")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(alignment: .bottom, spacing: Spacing.inline) {
                                Text("85%")
                                    .font(.title3)
                                    .fontWeight(.semibold)

                                Text("양호")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: Spacing.inline) {
                                Image(systemName: "arrow.up")
                                    .font(.caption)
                                    .foregroundColor(.green)

                                Text("+5%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        }

                        Spacer()
                    }

                    // 차트 섹션
                    VStack(alignment: .leading, spacing: Spacing.content) {
                        Text("일간 수면 시간 변화")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        BarChartView(
                            data: selectedPeriod == .week ? weeklySleepData : monthlySleepData,
                            color: .blue
                        )
                        .frame(height: 140)
                    }
                }
                .padding()
            }
    }

    private var weeklySleepData: [Double] {
        [6.5, 7.2, 6.8, 8.1, 7.5, 7.0, 7.8]
    }

    private var monthlySleepData: [Double] {
        [7.0, 7.5, 6.8, 7.2, 7.8, 7.1, 6.9, 7.6]
    }
}
