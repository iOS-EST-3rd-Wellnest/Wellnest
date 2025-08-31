//
//  BarChartView.swift
//  Wellnest
//
//  Created by junil on 8/11/25.
//

import SwiftUI

struct BarChartView: View {
    let data: [Double]
    let color: Color
    let period: ChartPeriod
    let dataType: DataType

    private var maxValue: Double {
        data.max() ?? 1
    }

    private var xAxisLabels: [String] {
        switch period {
        case .today:
            return ["6시", "9시", "12시", "15시", "18시", "21시", "24시"]
        case .week:
            return ["월", "화", "수", "목", "금", "토", "일"]
        case .month:
            return getWeeksInCurrentMonth().enumerated().map { "\($0.offset + 1)주" }
        }
    }

    private var yAxisValues: [Double] {
        switch dataType {
        case .steps:
            switch period {
            case .today:
                let max = maxValue
                if max <= 500 {
                    return [0, 100, 200, 300, 400, 500]
                } else if max <= 2000 {
                    return [0, 500, 1000, 1500, 2000]
                } else {
                    let step = (max / 4).rounded(.up)
                    return [0, step, step * 2, step * 3, step * 4]
                }
            case .week, .month:
                let max = maxValue
                if max <= 1000 {
                    return [0, 250, 500, 750, 1000]
                } else if max <= 5000 {
                    return [0, 1000, 2000, 3000, 4000, 5000]
                } else if max <= 10000 {
                    return [0, 2500, 5000, 7500, 10000]
                } else {
                    let step = (max / 4).rounded(.up)
                    return [0, step, step * 2, step * 3, step * 4]
                }
            }
        case .sleep:
            return [0, 2, 4, 6, 8, 10]
        }
    }

    private func getWeeksInCurrentMonth() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        guard let monthRange = calendar.range(of: .weekOfMonth, in: .month, for: today) else {
            return []
        }

        return Array(monthRange).map { _ in today }
    }

    var body: some View {
        if dataType == .sleep && period == .today {
            // 수면 타임라인 뷰
            sleepTimelineView
        } else {
            // 일반 바 차트
            regularBarChartView
        }
    }

    private var sleepTimelineView: some View {
        VStack(spacing: 12) {
            // 시간축
            HStack {
                ForEach(["23:00", "02:00", "05:00", "08:00"], id: \.self) { time in
                    Text(time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 8)

            // 수면 바
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.6)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 32)
                    .padding(.horizontal, 8)
            }
            .frame(height: 32)
        }
    }

    private var regularBarChartView: some View {
        HStack(spacing: 0) {
            // Y축 레이블
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(yAxisValues.reversed(), id: \.self) { value in
                    HStack {
                        Text(formatYAxisLabel(value))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 45, height: 160)
            .padding(.trailing, 5)

            VStack(spacing: 8) {
                // 차트 영역
                ZStack {
                    // 격자선
                    VStack(spacing: 0) {
                        ForEach(yAxisValues.reversed().dropLast(), id: \.self) { _ in
                            HStack {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.1))
                                    .frame(height: 0.5)
                            }
                            Spacer()
                        }
                    }

                    // 바 차트
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                            if value > 0 {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(color.gradient)
                                    .frame(height: barHeight(for: value))
                            } else {
                                Spacer()
                                    .frame(height: 2)
                            }
                            if index < data.count - 1 {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 160)

                // X축 레이블
                HStack(spacing: 0) {
                    ForEach(xAxisLabels, id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 14)
                .padding(.horizontal, 4)
            }
        }
        .padding(.leading, -14)
    }

    private func barHeight(for value: Double) -> CGFloat {
        guard maxValue > 0 else { return 2 }
        let ratio = value / maxValue
        return CGFloat(ratio) * 160
    }

    private func formatYAxisLabel(_ value: Double) -> String {
        switch dataType {
        case .steps:
            if value >= 10000 {
                return "\(String(format: "%.1f", value / 10000))만"
            } else if value >= 1000 {
                return "\(Int(value / 1000))천"
            } else if value == 0 {
                return "0"
            } else {
                return "\(Int(value))"
            }
        case .sleep:
            if value == 0 {
                return "0"
            } else {
                return "\(Int(value))시간"
            }
        }
    }
}
