//
//  ExerciseStatChartCardView.swift
//  Wellnest
//
//  Created by junil on 8/12/25.
//

import SwiftUI

struct ExerciseStatChartCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    let exerciseData: ExerciseData
    @State private var selectedPeriod: ChartPeriod = .week

    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.large)
            .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
            .frame(minHeight: 360)
            .defaultShadow()
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: Spacing.content) {
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

                        Picker("기간", selection: $selectedPeriod) {
                            ForEach(ChartPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 150)
                    }

                    HStack(spacing: Spacing.layout * 2) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("걸음 수")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(alignment: .bottom, spacing: Spacing.inline) {
                                Text(formatStepsDisplay())
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text(getStepsLabel())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            HStack(spacing: Spacing.inline) {
                                Image(systemName: getStepsChangeIcon())
                                    .font(.caption)
                                    .foregroundColor(getStepsChangeColor())
                                Text(getStepsChangeText())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(getStepsChangeColor())
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("칼로리")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(alignment: .bottom, spacing: Spacing.inline) {
                                Text(formatCaloriesDisplay())
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text(getCaloriesLabel())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            HStack(spacing: Spacing.inline) {
                                Image(systemName: getCaloriesChangeIcon())
                                    .font(.caption)
                                    .foregroundColor(getCaloriesChangeColor())
                                Text(getCaloriesChangeText())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(getCaloriesChangeColor())
                            }
                        }
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: Spacing.layout) {
                        Text(getChartTitle())
                            .font(.caption)
                            .foregroundColor(.secondary)

                        BarChartView(
                            data: currentChartData,
                            color: .orange,
                            period: selectedPeriod,
                            dataType: .steps
                        )
                        .frame(height: 140)
                    }
                }
                .padding(16)
            }
    }

    private var currentChartData: [Double] {
        switch selectedPeriod {
        case .today:
            return generateTodayData()
        case .week:
            return exerciseData.weeklySteps
        case .month:
            return exerciseData.monthlySteps
        }
    }

    private func generateTodayData() -> [Double] {
        // 오늘의 시간대별 걸음수 (현실적인 패턴)
        let totalSteps = Double(exerciseData.averageSteps)
        let hourlyDistribution = [0.02, 0.08, 0.12, 0.18, 0.20, 0.25, 0.15] // 더 현실적인 분포
        return hourlyDistribution.map { $0 * totalSteps }
    }

    private func formatStepsDisplay() -> String {
        switch selectedPeriod {
        case .today:
            let steps = exerciseData.averageSteps
            if steps >= 10000 {
                return String(format: "%.1f만", Double(steps) / 10000)
            } else if steps >= 1000 {
                return String(format: "%.1f천", Double(steps) / 1000)
            } else {
                return "\(steps)"
            }
        case .week:
            let avg = Int(exerciseData.weeklySteps.reduce(0, +) / Double(exerciseData.weeklySteps.count))
            if avg >= 10000 {
                return String(format: "%.1f만", Double(avg) / 10000)
            } else if avg >= 1000 {
                return String(format: "%.1f천", Double(avg) / 1000)
            } else {
                return "\(avg)"
            }
        case .month:
            let avg = Int(exerciseData.monthlySteps.reduce(0, +) / Double(exerciseData.monthlySteps.count))
            if avg >= 10000 {
                return String(format: "%.1f만", Double(avg) / 10000)
            } else if avg >= 1000 {
                return String(format: "%.1f천", Double(avg) / 1000)
            } else {
                return "\(avg)"
            }
        }
    }

    private func formatCaloriesDisplay() -> String {
        "\(exerciseData.averageCalories)"
    }

    private func getStepsLabel() -> String {
        switch selectedPeriod {
        case .today:
            return "걸음"
        case .week:
            return "걸음"
        case .month:
            return "걸음"
        }
    }

    private func getCaloriesLabel() -> String {
        switch selectedPeriod {
        case .today:
            return "kcal"
        case .week:
            return "kcal"
        case .month:
            return "kcal"
        }
    }

    private func getChartTitle() -> String {
        switch selectedPeriod {
        case .today:
            return "시간대별 걸음 수"
        case .week:
            return "일간 걸음 수 변화"
        case .month:
            return "주간 걸음 수 변화"
        }
    }

    private func getStepsChangeIcon() -> String {
        let change = getStepsChange()
        if change > 0 {
            return "arrow.up"
        } else if change < 0 {
            return "arrow.down"
        } else {
            return "minus"
        }
    }

    private func getStepsChangeColor() -> Color {
        let change = getStepsChange()
        if change > 0 {
            return .green
        } else if change < 0 {
            return .red
        } else {
            return .gray
        }
    }

    private func getStepsChangeText() -> String {
        let change = getStepsChange()
        if change > 0 {
            return "+\(change)%"
        } else if change < 0 {
            return "\(change)%"
        } else {
            return "유지"
        }
    }

    private func getStepsChange() -> Int {
        switch selectedPeriod {
        case .today:
            return exerciseData.dailyStepsChange
        case .week:
            return exerciseData.weeklyStepsChange
        case .month:
            return exerciseData.monthlyStepsChange
        }
    }

    private func getCaloriesChangeIcon() -> String {
        let change = getCaloriesChange()
        if change > 0 {
            return "arrow.up"
        } else if change < 0 {
            return "arrow.down"
        } else {
            return "minus"
        }
    }

    private func getCaloriesChangeColor() -> Color {
        let change = getCaloriesChange()
        if change > 0 {
            return .green
        } else if change < 0 {
            return .red
        } else {
            return .gray
        }
    }

    private func getCaloriesChangeText() -> String {
        let change = getCaloriesChange()
        if change > 0 {
            return "+\(change)%"
        } else if change < 0 {
            return "\(change)%"
        } else {
            return "유지"
        }
    }

    private func getCaloriesChange() -> Int {
        switch selectedPeriod {
        case .today:
            return exerciseData.dailyCaloriesChange
        case .week:
            return exerciseData.weeklyCaloriesChange
        case .month:
            return exerciseData.monthlyCaloriesChange
        }
    }
}

#Preview {
    AnalyticsView()
}
