//
//  Date+Modifier.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import SwiftUI

extension Date {
    // 정규화 (시/분/초 제거 0시 0분 0초)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date{
        Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: self)
        ) ?? self
    }

    var dayNumber: Int {
        Calendar.current.component(.day, from: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    func filledWeekDates() -> [Date] {
        let calendar = Calendar.current

        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: self) else { return [] }
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekInterval.start)
        }
    }

    func filledDatesOfMonth() -> [Date] {
        let calendar = Calendar.current

        guard let range = calendar.range(of: .day, in: .month, for: self),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: self)) else {
            return []
        }

        var dates: [Date] = []

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)

        // 이전 달
        let leadingEmptyCnt = (firstWeekday + 7 - calendar.firstWeekday) % 7

        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: self),
           let previousRange = calendar.range(of: .day, in: .month, for: previousMonth),
           let previousFirstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: previousMonth)) {

            for day in 0..<leadingEmptyCnt {
                if let date = calendar.date(byAdding: .day, value: previousRange.count - leadingEmptyCnt + day, to: previousFirstOfMonth) {
                    dates.append(date)
                }
            }
        }

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                dates.append(date)
            }
        }

        // 다음 달
        let trailingEmptyCnt = (7 - (dates.count % 7)) % 7

        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: self),
           let nextFirstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) {

            for day in 0..<trailingEmptyCnt {
                if let date = calendar.date(byAdding: .day, value: day, to: nextFirstOfMonth) {
                    dates.append(date)
                }
            }
        }

        return dates
    }
}

// Color
extension Date {
    var weekdayIndex: Int {
        Calendar.current.component(.weekday, from: self) - 1
    }

    var weekdayColor: Color {
        Date.weekdayColor(at: weekdayIndex)
    }

    static func weekdayColor(at index: Int) -> Color {
        switch index {
        case 0: return .red // 일요일
        case 6: return .blue // 토요일
        default: return .primary
        }
    }
}
