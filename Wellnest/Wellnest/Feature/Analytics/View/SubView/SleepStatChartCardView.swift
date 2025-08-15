//
//  SleepStatChartCardView.swift
//  Wellnest
//
//  Created by junil on 8/12/25.
//

import SwiftUI

struct SleepStatChartCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: SleepChartViewModel

    init(sleepData: SleepData) {
        self._viewModel = StateObject(wrappedValue: SleepChartViewModel(sleepData: sleepData))
    }

    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.large)
            .fill(colorScheme == .dark ? Color(.gray) : .white)
            .frame(minHeight: 320)
            .defaultShadow()
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: Spacing.content) {
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

                        Picker("기간", selection: $viewModel.selectedPeriod) {
                            ForEach(ChartPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 100)
                    }

                    HStack(spacing: Spacing.layout * 2) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("수면 시간")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(alignment: .bottom, spacing: Spacing.inline) {
                                Text(viewModel.averageSleepTime)
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
                                Text(viewModel.sleepQuality)
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
                                Text(viewModel.qualityChangeText)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: Spacing.content) {
                        Text("일간 수면 시간 변화")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        BarChartView(
                            data: viewModel.currentChartData,
                            color: .blue
                        )
                        .frame(height: 140)
                    }
                }
                .padding()
            }
    }
}
