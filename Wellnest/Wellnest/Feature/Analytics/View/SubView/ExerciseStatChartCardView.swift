//
//  ExerciseStatChartCardView.swift
//  Wellnest
//
//  Created by junil on 8/12/25.
//

import SwiftUI

struct ExerciseStatChartCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ExerciseChartViewModel

    init(exerciseData: ExerciseData) {
        self._viewModel = StateObject(wrappedValue: ExerciseChartViewModel(exerciseData: exerciseData))
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
                        Picker("기간", selection: $viewModel.selectedPeriod) {
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
                                Text(viewModel.averageSteps)
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
                                Text(viewModel.stepsChangeText)
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
                                Text(viewModel.averageCalories)
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
                                Text(viewModel.caloriesChangeText)
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
                            data: viewModel.currentChartData,
                            color: .orange
                        )
                        .frame(height: 140)
                    }
                }
                .padding()
            }
    }
}
