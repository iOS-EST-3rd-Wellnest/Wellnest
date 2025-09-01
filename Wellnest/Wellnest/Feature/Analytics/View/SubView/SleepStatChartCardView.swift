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
            header
            summaryRow

            VStack(alignment: .leading, spacing: 24) {
                Text(chartTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Group {
                    if selectedPeriod == .today {
                        Color.clear
                            .frame(height: 140) // 차트 높이 유지
                            .transition(.identity)
                    } else if let series = selectedSeries {
                        BarChartView(
                            data: series,
                            dates: selectedDates,
                            color: .blue,
                            period: selectedPeriod,
                            dataType: .sleep
                        )
                    } else {
                        placeholderChart
                    }
                }
            }
            .padding(.top, Spacing.content)
        }
        .padding()
        .padding(.bottom, Spacing.layout)
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
private extension SleepStatChartCardView {
    var header: some View {
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
            .pickerStyle(.segmented)
            .frame(width: 150)
        }
    }

    var summaryRow: some View {
        HStack(spacing: 0) {
            // 총 수면 시간 (기간 합계)
            VStack(alignment: .leading, spacing: 4) {
                Text("총 수면 시간")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(alignment: .bottom, spacing: Spacing.inline) {
                    Text(formatHM(minutes: totalSleepMinutes(for: selectedPeriod)))
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                if let change = sleepChangePercent(for: selectedPeriod) {
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

            // 평균 수면 시간 — 오늘은 숨김, 주/월만 표시 (데이터 있는 날만으로 평균)
            if let avgMin = averageSleepMinutes(for: selectedPeriod) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("평균 수면 시간")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(alignment: .bottom, spacing: Spacing.inline) {
                        Text(formatHM(minutes: avgMin))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    if let change = sleepChangePercent(for: selectedPeriod) {
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
        if !sleepData.isHealthKitConnected {
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(.ultraThinMaterial)
                .overlay {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.text.square" )
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)

                        VStack(spacing: 8) {
                            Text("건강 앱 연동 필요")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("설정에서 건강 앱을 연동하면\n수면 데이터를 확인할 수 있어요")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .allowsHitTesting(true)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
                .transition(.opacity)
        }
    }
}

// MARK: - Data & formatting
private extension SleepStatChartCardView {
    /// 선택된 기간의 차트용 값 시리즈 (시간 단위)
    var selectedSeries: [Double]? {
        switch selectedPeriod {
        case .today:
            // 오늘은 수면 타임라인(세션)으로 대체되므로, 값 시리즈는 빈 배열로 전달해도 OK
            return []

        case .week:
            let arrMin = sleepData.sleep7dDailyMinutes.map(\.value)
            let arrHr = arrMin.map { $0 / 60.0 }
            return arrHr.contains(where: { $0 > 0 }) ? arrHr : nil

        case .month:
            let arrMin = sleepData.sleep30dDailyMinutes.map(\.value)
            let arrHr = arrMin.map { $0 / 60.0 }
            return arrHr.contains(where: { $0 > 0 }) ? arrHr : nil
        }
    }

    var selectedDates: [Date]? {
        switch selectedPeriod {
        case .today:
            return nil
        case .week:
            return sleepData.sleep7dDailyMinutes.map(\.date)
        case .month:
            return sleepData.sleep30dDailyMinutes.map(\.date)
        }
    }

    var chartTitle: String {
        switch selectedPeriod {
        case .today: return ""
        case .week:  return "일간 수면 시간"
        case .month: return "일간 수면 시간(30일)"
        }
    }

    // 총합(분) — 오늘은 오늘 분, 주/월은 일별 분의 합
    func totalSleepMinutes(for period: ChartPeriod) -> Int {
        switch period {
        case .today:
            return Int(sleepData.sleepTodayMinutes)
        case .week:
            let arr = sleepData.sleep7dDailyMinutes.map(\.value)
            return Int(arr.reduce(0, +).rounded())
        case .month:
            let arr = sleepData.sleep30dDailyMinutes.map(\.value)
            return Int(arr.reduce(0, +).rounded())
        }
    }

    // 평균(분) — 오늘은 nil, 주/월은 "데이터 있는 날만"으로 나눔
    func averageSleepMinutes(for period: ChartPeriod) -> Int? {
        switch period {
        case .today:
            return nil
        case .week:
            let arr = sleepData.sleep7dDailyMinutes.map(\.value).filter { $0 > 0 }
            guard !arr.isEmpty else { return 0 }
            return Int((arr.reduce(0, +) / Double(arr.count)).rounded())
        case .month:
            let arr = sleepData.sleep30dDailyMinutes.map(\.value).filter { $0 > 0 }
            guard !arr.isEmpty else { return 0 }
            return Int((arr.reduce(0, +) / Double(arr.count)).rounded())
        }
    }

    // 오늘용 간단 단계 분배(시각적 보기용) — 필요 시 제거 가능
    func pseudoStagesSplit(totalHours: Double) -> [Double] {
        guard totalHours > 0 else { return [] }
        let weights: [Double] = [0.12, 0.18, 0.22, 0.20, 0.18, 0.10]
        let wsum = weights.reduce(0, +)
        return weights.map { totalHours * ($0 / wsum) }
    }

    func formatHM(minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)시간 \(m)분" }
        if h > 0 { return "\(h)시간" }
        if m > 0 { return "\(m)분" }
        return "0분"
    }
}

// MARK: - Change(증감) 계산
private extension SleepStatChartCardView {
    func sleepChangePercent(for period: ChartPeriod) -> Int? {
        switch period {
        case .today:
            // 오늘 vs 어제 (7일 시리즈의 마지막 2개 비교)
            let series = sleepData.sleep7dDailyMinutes
                .sorted { $0.date < $1.date }
                .map(\.value) // 분
            guard series.count >= 2 else { return nil }
            let today = series.last ?? 0
            let yesterday = series.dropLast().last ?? 0
            return pctChange(current: today, baseline: yesterday)

        case .week:
            // 최근 7일 평균 vs 그 이전 7일 평균 (30일 시리즈 필요)
            let series = sleepData.sleep30dDailyMinutes
                .sorted { $0.date < $1.date }
                .map(\.value) // 분
            return weekOverWeekChange(series)

        case .month:
            // 30일 vs 이전 30일은 현재 데이터 모델로 계산 보류
            return nil
        }
    }

    func weekOverWeekChange(_ series: [Double]) -> Int? {
        guard series.count >= 14 else { return nil }
        let last7 = Array(series.suffix(7))
        let prev7 = Array(series.dropLast(7).suffix(7))
        let a = last7.reduce(0, +) / Double(last7.count)   // 분
        let b = prev7.reduce(0, +) / Double(prev7.count)   // 분
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
}
