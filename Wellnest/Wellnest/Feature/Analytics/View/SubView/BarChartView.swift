//
//  BarChartView.swift
//  Wellnest
//
//  Created by junil on 8/11/25.
//

import SwiftUI

// MARK: - 메인 차트 뷰
struct BarChartView: View {
    /// 값 시리즈
    let data: [Double]
    /// 월간 라벨용 실제 날짜 시리즈 (예: ExerciseData.steps30dDaily.map(\.date))
    /// - today/week에서는 무시됨
    let dates: [Date]?
    /// 막대 컬러
    let color: Color
    /// 기간
    let period: ChartPeriod
    /// 표기 단위
    let dataType: DataType

    @State private var selectedIndex: Int? = nil
    @State private var animationProgress: CGFloat = 0

    // Tunables
    private let chartHeight: CGFloat = 140
    private let barSpacing: CGFloat = 6
    private let barCornerRadius: CGFloat = 3
    private let labelHeight: CGFloat = 20
    private let minBarPixel: CGFloat = 2   // 데이터 0이어도 최소 높이

    // Tooltip (막대 폭과 무관한 고정 폭)
    private let tooltipWidth: CGFloat = 72

    var body: some View {
        VStack(spacing: 12) {
            chartWithLabels
                .frame(height: chartHeight + labelHeight)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) { animationProgress = 1.0 }
        }
        .onChange(of: data) { _ in
            animationProgress = 0
            withAnimation(.easeOut(duration: 0.6)) { animationProgress = 1.0 }
            selectedIndex = nil
        }
    }
}

// MARK: - 차트 + 라벨 통합 컴포넌트
private extension BarChartView {

    var chartWithLabels: some View {
        GeometryReader { geo in
            let count = referenceCount(for: period)

            // 값/날짜 시리즈를 기간 기준 개수로 패딩
            let series = paddedSeries(data, to: count)
            let dateSeries = paddedDates(dates, to: count)

            let barWidth = calculateBarWidth(containerWidth: geo.size.width, referenceCount: count)
            let contentWidth = totalContentWidth(forCount: count, barWidth: barWidth)
            let maxValue = max(series.max() ?? 0, 1)

            let forceScrollForMonth = (period == .month)
            let needsScrolling = forceScrollForMonth || contentWidth > geo.size.width

            Group {
                if needsScrolling {
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(spacing: 12) {
                            barContent(series: series, barWidth: barWidth, maxValue: maxValue)
                                .frame(width: contentWidth, height: chartHeight, alignment: .bottom)
                            labelContent(count: count, barWidth: barWidth, dateSeries: dateSeries)
                                .frame(width: contentWidth, height: labelHeight, alignment: .top)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        barContent(series: series, barWidth: barWidth, maxValue: maxValue)
                            .frame(maxWidth: .infinity, minHeight: chartHeight, maxHeight: chartHeight, alignment: .bottom)
                        labelContent(count: count, barWidth: barWidth, dateSeries: dateSeries)
                            .frame(maxWidth: .infinity, minHeight: labelHeight, maxHeight: labelHeight, alignment: .top)
                    }
                }
            }
        }
        .dynamicTypeSize(.medium) // 차트 영역은 고정 폰트 크기
    }

    func barContent(series: [Double], barWidth: CGFloat, maxValue: Double) -> some View {
        HStack(alignment: .bottom, spacing: barSpacing) {
            ForEach(series.indices, id: \.self) { index in
                let value = series[index]
                let isSelected = (selectedIndex == index)

                RoundedRectangle(cornerRadius: barCornerRadius)
                    .fill(barGradient(isSelected: selectedIndex == index))
                    .frame(width: barWidth, height: barHeight(value: value, maxValue: maxValue))
                    .overlay(alignment: .top) {
                        if selectedIndex == index {
                            Text(formatValue(value))
                                .font(.system(size: 11, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .frame(width: tooltipWidth) // 고정 폭
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(.primary.opacity(0.08), lineWidth: 0.5)
                                )
                                .offset(y: -30)             // 막대 꼭대기에서 위로 (원하면 -8/-12 등으로 조정)
                                .allowsHitTesting(false)
                                .transition(.opacity)
                        }
                    }
                    .scaleEffect(y: animationProgress, anchor: .bottom)
                    .contentShape(Rectangle()) // 탭 영역 확장
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedIndex = (selectedIndex == index) ? nil : index
                        }
                    }
                    .zIndex(isSelected ? 1 : 0)
            }
        }
    }

    func labelContent(count: Int, barWidth: CGFloat, dateSeries: [Date?]) -> some View {
        HStack(alignment: .top, spacing: barSpacing) {
            ForEach(0..<count, id: \.self) { i in
                Text(xLabel(at: i, totalCount: count, dateSeries: dateSeries))
                    .font(.system(size: 10))     // 고정 폰트
                    .foregroundStyle(.secondary)
                    .frame(width: barWidth)
                    .lineLimit(1)
                    .minimumScaleFactor(1.0)     // 축소/확대 방지
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - 계산 & 유틸
private extension BarChartView {

    func referenceCount(for period: ChartPeriod) -> Int {
        switch period {
        case .today: return 8   // 0,3,6,9,12,15,18,21시
        case .week:  return 7   // 월~일
        case .month: return 30  // 월간 30개 기준(스크롤 허용)
        }
    }

    func paddedSeries(_ data: [Double], to count: Int) -> [Double] {
        if data.count >= count { return Array(data.prefix(count)) }
        return data + Array(repeating: 0, count: count - data.count)
    }

    func paddedDates(_ dates: [Date]?, to count: Int) -> [Date?] {
        guard let dates = dates else { return Array(repeating: nil, count: count) }
        if dates.count >= count { return Array(dates.prefix(count)) }
        return dates + Array(repeating: nil, count: count - dates.count)
    }

    func calculateBarWidth(containerWidth: CGFloat, referenceCount: Int) -> CGFloat {
        let minWidth: CGFloat = 8
        let maxWidth: CGFloat = 40
        let availableWidth = containerWidth - CGFloat(max(referenceCount - 1, 0)) * barSpacing
        let idealWidth = availableWidth / CGFloat(max(referenceCount, 1))

        let baseWidth = min(max(idealWidth, minWidth), maxWidth)

        // 월간은 막대 너비 2배
        return period == .month ? (baseWidth * 2) : baseWidth
    }

    func totalContentWidth(forCount count: Int, barWidth: CGFloat) -> CGFloat {
        let totalBarWidth = barWidth * CGFloat(count)
        let totalSpacing = barSpacing * CGFloat(max(count - 1, 0))
        return totalBarWidth + totalSpacing
    }

    func barHeight(value: Double, maxValue: Double) -> CGFloat {
        guard maxValue > 0 else { return minBarPixel }
        let ratio = value / maxValue
        return max(minBarPixel, CGFloat(ratio) * chartHeight * 0.85) // 최소 높이 보장
    }

    func barGradient(isSelected: Bool) -> LinearGradient {
        LinearGradient(
            colors: isSelected
                ? [color.opacity(0.9), color]
                : [color.opacity(0.7), color.opacity(0.9)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // 라벨은 기간 규칙으로 생성 (월간은 실제 날짜의 '일' 표시)
    func xLabel(at index: Int, totalCount: Int, dateSeries: [Date?]) -> String {
        switch period {
        case .today:
            let hour = index * 3
            switch hour {
            case 0:  return "0시"
            case 12: return "12시"
            case 18: return "18시"
            default: return "\(hour)시"
            }

        case .week:
            let weekdays = ["월", "화", "수", "목", "금", "토", "일"]
            return weekdays[min(index, weekdays.count - 1)]

        case .month:
            let position = index + 1
            guard position % 5 == 0 else { return "" }

            if index < dateSeries.count, let date = dateSeries[index] {
                let day = Calendar.current.component(.day, from: date)
                return "\(day)"
            } else {
                return "\(position)"
            }
        }
    }

    func formatValue(_ value: Double) -> String {
        switch dataType {
        case .steps:
            if value >= 10_000 {
                return String(format: "%.1f만", value / 10_000)
            } else if value >= 1_000 {
                return String(format: "%.1f천", value / 1_000)
            } else {
                return String(format: "%.0f", value)
            }

        case .sleep:
            let hours = Int(value)
            let minutes = Int((value - Double(hours)) * 60)
            return minutes == 0 ? "\(hours)시간" : "\(hours)시간 \(minutes)분"
        }
    }
}
