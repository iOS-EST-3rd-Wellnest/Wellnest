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
        VStack(alignment: .leading, spacing: Spacing.content) {
            header

            // 상단 요약(걸음만)
            summaryRow

            // 차트
            VStack(alignment: .leading, spacing: 24) {
                Text(getChartTitle())
                    .font(.caption)
                    .foregroundColor(.secondary)

                Group {
                    if let series = selectedStepsSeries, !series.isEmpty {
                        BarChartView(
                            data: series,
                            dates: selectedDates,
                            color: .wellnestOrange,
                            period: selectedPeriod,
                            dataType: .steps
                        )
                        .frame(maxWidth: .infinity)
//                        .frame(height: 140)
                        .transition(.opacity)
                    } else {
                        placeholderChart
                    }
                }
            }
            .padding(.top, Spacing.content)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
//        .frame(maxHeight: 420)
        .padding()
        .roundedBorder(cornerRadius: CornerRadius.large)
        .defaultShadow()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(.wellnestBackgroundCard)
        )
        .overlay(disabledOverlay)
    }
}

// MARK: - Subviews
private extension ExerciseStatChartCardView {
    var header: some View {
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
            .pickerStyle(.segmented)
            .frame(width: 150)
        }
    }

    var summaryRow: some View {
        HStack(spacing: 0) {
            // 총 걸음 수 (기간 합계)
            VStack(alignment: .leading, spacing: 4) {
                Text("총 걸음 수")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(alignment: .bottom, spacing: Spacing.inline) {
                    Text(formatNumber(totalSteps(for: selectedPeriod)))
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("걸음")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let change = stepsChangePercent(for: selectedPeriod) {
                    HStack(spacing: Spacing.inline) {
                        Image(systemName: icon(forChange: change))
                            .font(.caption)
                            .foregroundColor(color(forChange: change))
                        Text(formattedChange(change))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(color(forChange: change))
                    }
                } else {
                    Text("—")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 140, alignment: .leading)

            // 평균 걸음 수 — 오늘은 숨김, 주/월만 표시
            if let avg = averageSteps(for: selectedPeriod) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("평균 걸음 수")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(alignment: .bottom, spacing: Spacing.inline) {
                        Text(formatNumber(avg))
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("걸음")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let change = stepsChangePercent(for: selectedPeriod) {
                        HStack(spacing: Spacing.inline) {
                            Image(systemName: icon(forChange: change))
                                .font(.caption)
                                .foregroundColor(color(forChange: change))
                            Text(formattedChange(change))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(color(forChange: change))
                        }
                    } else {
                        Text("—")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 140, alignment: .leading)
            }
        }
    }

    var placeholderChart: some View {
        RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
            .fill(.ultraThinMaterial)
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

    @ViewBuilder
    var disabledOverlay: some View {
        if !exerciseData.isHealthKitConnected {
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(.ultraThinMaterial)
                .overlay {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        VStack(spacing: 8) {
                            Text("건강 앱 연동 필요")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("설정에서 건강 앱을 연동하면\n운동 데이터를 확인할 수 있어요")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                }
                .allowsHitTesting(true)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
                .transition(.opacity)
        }
    }
}

// MARK: - Data mapping helpers
private extension ExerciseStatChartCardView {
    var selectedStepsSeries: [Double]? {
        switch selectedPeriod {
        case .today:
            let arr = exerciseData.stepsToday3hBuckets.map(\.value)
            return arr.isEmpty ? nil : arr
        case .week:
            let arr = exerciseData.steps7dDaily.map(\.value)
            return arr.contains(where: { $0 > 0 }) ? arr : nil
        case .month:
            let arr = exerciseData.steps30dDaily.map(\.value)
            return arr.contains(where: { $0 > 0 }) ? arr : nil
        }
    }

    var selectedDates: [Date]? {
        switch selectedPeriod {
        case .today:
            return nil
        case .week:
            return exerciseData.steps7dDaily.map(\.date)
        case .month:
            return exerciseData.steps30dDaily.map(\.date)
        }
    }

    // 총합 (기간별)
    func totalSteps(for period: ChartPeriod) -> Int {
        switch period {
        case .today:
            return exerciseData.stepsTodayTotal
        case .week:
            return Int(exerciseData.steps7dDaily.map(\.value).reduce(0, +).rounded())
        case .month:
            return Int(exerciseData.steps30dDaily.map(\.value).reduce(0, +).rounded())
        }
    }

    // 평균 (주/월만, 오늘은 nil)
    func averageSteps(for period: ChartPeriod) -> Int? {
        switch period {
        case .today:
            return nil

        case .week:
            let arr = exerciseData.steps7dDaily.map(\.value).filter { $0 > 0 }
            guard !arr.isEmpty else { return 0 }
            return Int((arr.reduce(0, +) / Double(arr.count)).rounded())

        case .month:
            let arr = exerciseData.steps30dDaily.map(\.value).filter { $0 > 0 }
            guard !arr.isEmpty else { return 0 }
            return Int((arr.reduce(0, +) / Double(arr.count)).rounded())
        }
    }

    // 숫자 포맷(만/천)
    func formatNumber(_ value: Int) -> String {
        if value >= 10_000 {
            return String(format: "%.1f만", Double(value) / 10_000)
        } else if value >= 1_000 {
            return String(format: "%.1f천", Double(value) / 1_000)
        } else {
            return "\(value)"
        }
    }

    func getChartTitle() -> String {
        switch selectedPeriod {
        case .today: return "시간대별 걸음 수"
        case .week:  return "일간 걸음 수 변화"
        case .month: return "일간 걸음 수 변화(30일)"
        }
    }
}

// MARK: - Change(증감) 계산
private extension ExerciseStatChartCardView {
    func stepsChangePercent(for period: ChartPeriod) -> Int? {
        switch period {
        case .today:
            // 오늘 vs 어제: 7일 시리즈의 마지막 2개 비교
            let series = exerciseData.steps7dDaily.sorted { $0.date < $1.date }.map(\.value)
            guard series.count >= 2 else { return nil }
            let today = series.last ?? 0
            let yesterday = series.dropLast().last ?? 0
            return pctChange(current: today, baseline: yesterday)

        case .week:
            // 최근 7일 평균 vs 그 이전 7일 평균 (30일 시리즈 이용)
            let series = exerciseData.steps30dDaily.sorted { $0.date < $1.date }.map(\.value)
            return weekOverWeekChange(series)

        case .month:
            // 30일 vs 이전 30일은 별도 데이터 없으므로 nil
            return nil
        }
    }

    func weekOverWeekChange(_ series: [Double]) -> Int? {
        guard series.count >= 14 else { return nil }
        let last7 = Array(series.suffix(7))
        let prev7 = Array(series.dropLast(7).suffix(7))
        let a = average(of: last7)
        let b = average(of: prev7)
        return pctChange(current: a, baseline: b)
    }

    func pctChange<T: BinaryFloatingPoint>(current: T, baseline: T) -> Int? {
        guard baseline > 0 else { return nil }
        let pct = (Double(current - baseline) / Double(baseline)) * 100
        return Int(pct.rounded())
    }

    func icon(forChange c: Int) -> String {
        if c > 0 { return "arrow.up" }
        if c < 0 { return "arrow.down" }
        return "minus"
    }

    func color(forChange c: Int) -> Color {
        if c > 0 { return .green }
        if c < 0 { return .red }
        return .gray
    }

    func formattedChange(_ c: Int) -> String {
        c == 0 ? "유지" : (c > 0 ? "+\(c)%" : "\(c)%")
    }

    func average(of arr: [Double]) -> Double {
        guard !arr.isEmpty else { return 0 }
        return arr.reduce(0, +) / Double(arr.count)
    }
}

#if DEBUG
private extension ExerciseData {
    static func sample(isConnected: Bool = true) -> ExerciseData {
        let cal = Calendar.current
        let now = Date()
        let today0 = cal.startOfDay(for: now)

        // 오늘 3시간 버킷 (8개, 24h)
        let threeHourBuckets: [TimeBucket] = (0..<8).map { i in
            let start = cal.date(byAdding: .hour, value: i * 3, to: today0)!
            let end   = cal.date(byAdding: .hour, value: (i + 1) * 3, to: today0)!
            // 아침/저녁 피크를 조금 반영한 더미값
            let base = [0.05, 0.08, 0.10, 0.12, 0.18, 0.22, 0.17, 0.08][i]
            return TimeBucket(start: start, end: end, value: Double(Int(10000.0 * base)))
        }

        // 최근 7일 일별 걸음 (오름차순 날짜)
        let steps7dDaily: [DailyPoint] = (0..<7).map { i in
            let day = cal.date(byAdding: .day, value: -(6 - i), to: today0)! // 6일 전 ~ 오늘
            let v = [8200, 9100, 7800, 10200, 9600, 8800, 10400][i]
            return DailyPoint(date: day, value: Double(v))
        }

        // 최근 30일 일별 걸음
        let steps30dDaily: [DailyPoint] = (0..<30).map { i in
            let day = cal.date(byAdding: .day, value: -(29 - i), to: today0)!
            let base = 8500 + Int.random(in: -1800...1800)
            return DailyPoint(date: day, value: Double(max(0, base)))
        }

        let steps7dTotal = Int(steps7dDaily.map(\.value).reduce(0, +))
        let steps7dAvg   = steps7dTotal / max(1, steps7dDaily.count)
        let steps30dTotal = Int(steps30dDaily.map(\.value).reduce(0, +))
        let steps30dAvg   = steps30dTotal / max(1, steps30dDaily.count)

        return ExerciseData(
            // 오늘
            stepsTodayTotal: 10432,
            stepsToday3hBuckets: threeHourBuckets,

            // 1주(일별)
            steps7dDaily: steps7dDaily,
            steps7dTotal: steps7dTotal,
            steps7dAverage: steps7dAvg,

            // 1개월(일별)
            steps30dDaily: steps30dDaily,
            steps30dTotal: steps30dTotal,
            steps30dAverage: steps30dAvg,

            // 상태
            isHealthKitConnected: isConnected
        )
    }
}

#Preview("연동됨 • 라이트") {
    ExerciseStatChartCardView(exerciseData: .sample(isConnected: true))
        .padding()
        .background(Color(.systemBackground))
        .environment(\.colorScheme, .light)
}

#Preview("연동 안 됨 • 다크") {
    ExerciseStatChartCardView(exerciseData: .sample(isConnected: false))
        .padding()
        .background(Color(.systemBackground))
        .environment(\.colorScheme, .dark)
}
#endif
