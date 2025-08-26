//
//  ScheduleItem.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/3/25.
//

import SwiftUI

struct ScheduleItem: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let createdAt: Date
    let updatedAt: Date
    let backgroundColor: String
    let isAllDay: Bool
    let repeatRule: String?
    let hasRepeatEndDate: Bool
    let repeatEndDate: Date?
    var isCompleted: Bool
    let eventIdentifier: String?
}

struct ScheduleDayDisplay {
    let isAllDayForThatDate: Bool
    let displayStart: Date?
    let displayEnd: Date?
}

extension ScheduleItem {
    func display(on date: Date) -> ScheduleDayDisplay {
        let calendar = Calendar.current
        let day = date.startOfDay
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!

        if isAllDay {
            return .init(isAllDayForThatDate: true, displayStart: nil, displayEnd: nil)
        }

        if startDate <= day && endDate >= nextDay {
            return .init(isAllDayForThatDate: true, displayStart: nil, displayEnd: nil)
        }

        let start = max(startDate, day)
        let end   = min(endDate, nextDay)

        guard start < end else {
            return .init(isAllDayForThatDate: false, displayStart: nil, displayEnd: nil)
        }

        return .init(isAllDayForThatDate: false, displayStart: start, displayEnd: end)
    }
}
