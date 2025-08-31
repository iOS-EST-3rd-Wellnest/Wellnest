//
//  SleepStatChartCardView.swift
//  Wellnest
//
//  Created by junil on 8/12/25.
//

import SwiftUI

struct SleepStatChartCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    let sleepData: SleepData
    @State private var selectedPeriod: ChartPeriod = .week

    var body: some View {
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

                Picker("기간", selection: $selectedPeriod) {
                    ForEach(ChartPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(getSleepTitle())
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(alignment: .bottom, spacing: Spacing.inline) {
                        if sleepData.hasSleepTimeData {
                            Text(formatSleepTimeDisplay())
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(getSleepTimeLabel())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("--")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }

                    HStack(spacing: Spacing.inline) {
                        Image(systemName: getSleepTimeChangeIcon())
                            .font(.caption)
                            .foregroundColor(getSleepTimeChangeColor())
                        
                        Text(getSleepTimeChangeText())
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(getSleepTimeChangeColor())
                    }
                }
                .frame(width: 100, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(getSleepQualityTitle())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .bottom, spacing: Spacing.inline) {
                        if sleepData.hasSleepQualityData {
                            Text(formatSleepQualityDisplay())
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("--")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(spacing: Spacing.inline) {
                        Image(systemName: getSleepEfficiencyChangeIcon())
                            .font(.caption)
                            .foregroundColor(getSleepEfficiencyChangeColor())
                        
                        Text(getSleepEfficiencyChangeText())
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(getSleepEfficiencyChangeColor())
                    }
                }
                .frame(width: 100, alignment: .leading)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 24) {
                Text(getChartTitle())
                    .font(.caption)
                    .foregroundColor(.secondary)

                if sleepData.hasSleepTimeData {
                    ZStack {
                        BarChartView(
                            data: currentChartData,
                            color: .blue,
                            period: selectedPeriod,
                            dataType: .sleep
                        )
                        .frame(height: 140)
                    }
                } else {
                    RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                        .fill(.secondary.opacity(0.1))
                        .frame(height: 140)
                        .overlay {
                            VStack(spacing: Spacing.content) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text("해당 기간 데이터가 없어요")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .transition(.opacity)
                }
                
            }
            .padding(.top, Spacing.content)
        }
        .frame(maxHeight: 400)
        .padding()
        .padding(.bottom, Spacing.layout)
        .roundedBorder(cornerRadius: CornerRadius.large)
        .defaultShadow()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(.wellnestBackgroundCard)
        )
        .overlay {
            // 건강앱 연동 안되어 있는 경우에만 블러 처리
            if !sleepData.isHealthKitConnected {
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(.regularMaterial)
                    .overlay {
                        VStack(spacing: 16) {
                            Image(systemName: "heart.text.square" )
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 8) {
                                Text("건강 앱 연동 필요")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("설정에서 건강 앱을 연동하면\n수면 데이터를 확인할 수 있어요" )
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
            }
        }
    }

    private var currentChartData: [Double] {
        switch selectedPeriod {
        case .today:
            return generateTodaySleepData()
        case .week:
            return sleepData.weeklySleepHours
        case .month:
            return sleepData.monthlySleepHours
        }
    }

    private func generateTodaySleepData() -> [Double] {
        // 오늘은 수면 단계 분석 (REM, 깊은잠, 얕은잠 등)
        let totalSleep = sleepData.averageHours
        // 수면 단계별 시간 (더 현실적인 분포)
        let sleepStages = [1.5, 2.0, 1.8, 1.2, 0.3, 0.1, 0.1] // 7단계 수면 분석
        let multiplier = totalSleep / sleepStages.reduce(0, +)
        return sleepStages.map { $0 * multiplier }
    }

    private func formatSleepTimeDisplay() -> String {
        switch selectedPeriod {
        case .today:
            return formatSleepTime(sleepData.averageHours, sleepData.averageMinutes)
        case .week:
            let avgHours = sleepData.weeklySleepHours.reduce(0, +) / Double(sleepData.weeklySleepHours.count)
            let minutes = Int((avgHours.truncatingRemainder(dividingBy: 1)) * 60)
            return formatSleepTime(avgHours, minutes)
        case .month:
            let avgHours = sleepData.monthlySleepHours.reduce(0, +) / Double(sleepData.monthlySleepHours.count)
            let minutes = Int((avgHours.truncatingRemainder(dividingBy: 1)) * 60)
            return formatSleepTime(avgHours, minutes)
        }
    }

    private func formatSleepQualityDisplay() -> String {
        "\(sleepData.sleepQuality)"
    }

    private func getSleepTimeLabel() -> String {
        switch selectedPeriod {
        case .today:
            return ""
        case .week:
            return ""
        case .month:
            return ""
        }
    }

    private func getChartTitle() -> String {
        switch selectedPeriod {
        case .today:
            return "수면 단계별 분석"
        case .week:
            return "일간 수면 시간"
        case .month:
            return "주간 수면 시간"
        }
    }
    
    private func getSleepTitle() -> String {
        switch selectedPeriod {
        case .today:
            return "수면 시간"
        case .week:
            return "수면 시간(평균)"
        case .month:
            return "수면 시간(평균)"
        }
    }
    
    private func getSleepQualityTitle() -> String {
        switch selectedPeriod {
        case .today:
            return "수면 효율"
        case .week:
            return "수면 효율(평균)"
        case .month:
            return "수면 효율(평균)"
        }
    }

    private func formatSleepTime(_ hours: Double, _ minutes: Int) -> String {
        let hourInt = Int(hours)
        if hourInt > 0 && minutes > 0 {
            return "\(hourInt)시간 \(minutes)분"
        } else if hourInt > 0 {
            return "\(hourInt)시간"
        } else if minutes > 0 {
            return "\(minutes)분"
        } else {
            return "0분"
        }
    }

    private func getSleepTimeChangeIcon() -> String {
        let change = getSleepTimeChange()
        if change > 0 {
            return "arrow.up"
        } else if change < 0 {
            return "arrow.down"
        } else {
            return "minus"
        }
    }

    private func getSleepTimeChangeColor() -> Color {
        let change = getSleepTimeChange()
        if change > 0 {
            return .green
        } else if change < 0 {
            return .red
        } else {
            return .gray
        }
    }

    private func getSleepTimeChangeText() -> String {
        let change = getSleepTimeChange()
        if change > 0 {
            return "+\(change)%"
        } else if change < 0 {
            return "\(change)%"
        } else {
            return "유지"
        }
    }

    private func getSleepTimeChange() -> Int {
        switch selectedPeriod {
        case .today:
            return sleepData.dailySleepTimeChange
        case .week:
            return sleepData.weeklySleepTimeChange
        case .month:
            return sleepData.monthlySleepTimeChange
        }
    }

    private func getSleepEfficiencyChangeIcon() -> String {
        let change = getSleepEfficiencyChange()
        if change > 0 {
            return "arrow.up"
        } else if change < 0 {
            return "arrow.down"
        } else {
            return "minus"
        }
    }

    private func getSleepEfficiencyChangeColor() -> Color {
        let change = getSleepEfficiencyChange()
        if change > 0 {
            return .green
        } else if change < 0 {
            return .red
        } else {
            return .gray
        }
    }

    private func getSleepEfficiencyChangeText() -> String {
        let change = getSleepEfficiencyChange()
        if change > 0 {
            return "+\(change)%"
        } else if change < 0 {
            return "\(change)%"
        } else {
            return "유지"
        }
    }

    private func getSleepEfficiencyChange() -> Int {
        switch selectedPeriod {
        case .today:
            return sleepData.dailyQualityChange
        case .week:
            return sleepData.weeklyQualityChange
        case .month:
            return sleepData.monthlyQualityChange
        }
    }
}
