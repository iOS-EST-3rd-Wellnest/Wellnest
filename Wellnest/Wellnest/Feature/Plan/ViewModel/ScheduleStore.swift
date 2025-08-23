//
//  ScheduleStore.swift
//  Wellnest
//
//  Created by 박동언 on 8/12/25.
//

import SwiftUI

final class ScheduleStore: ObservableObject {
    @Published var scheduleItems: [ScheduleItem] = []

    private let calendar = Calendar.current
    private var schedulesByDate: [Date: [ScheduleItem]] = [:]

    init() {
        loadScheduleData()
    }

    func scheduleItems(for date: Date) -> [ScheduleItem] {
        return schedulesByDate[date.startOfDay] ?? []
    }

    func hasSchedule(for date: Date) -> Bool {
        return schedulesByDate[date.startOfDay] != nil
    }

    func loadScheduleData() {
        self.scheduleItems = DataLoader.loadScheduleItems()
        makeSchedulesByDateDictionary()
    }

    private func makeSchedulesByDateDictionary() {
        schedulesByDate.removeAll(keepingCapacity: true)

        for item in scheduleItems {
            if let repeatRuleString = item.repeatRule,
               let repeatRule = RepeatRule.from(string: repeatRuleString) {
                processRepeatingSchedule(item: item, repeatRule: repeatRule)
            } else {
                processNormalSchedule(item: item)
            }
        }

        for (date, items) in schedulesByDate {
            schedulesByDate[date] = items.sorted { first, second in
                if first.isAllDay && !second.isAllDay {
                    return true
                } else if !first.isAllDay && second.isAllDay {
                    return false
                } else {
                    return first.startDate < second.startDate
                }
            }
        }
    }

    private func processNormalSchedule(item: ScheduleItem) {
        let startDate = item.startDate.startOfDay
        let endDate = item.endDate.startOfDay

        var currentDate = startDate
        while currentDate <= endDate {
            schedulesByDate[currentDate, default: []].append(item)

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
    }

    private func processRepeatingSchedule(item: ScheduleItem, repeatRule: RepeatRule) {
        let endDate = item.hasRepeatEndDate ? item.repeatEndDate : nil

        let repeatDates = repeatRule.generateDates(
            from: item.startDate.startOfDay,
            until: endDate?.startOfDay
        )

        for repeatDate in repeatDates {
            let duration = calendar.dateComponents([.day], from: item.startDate.startOfDay, to: item.endDate.startOfDay).day ?? 0

            for dayOffset in 0...duration {
                guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: repeatDate) else { continue }

                if let endDate = endDate, targetDate > endDate {
                    break
                }

                schedulesByDate[targetDate, default: []].append(item)
            }
        }
    }

    func fetchSchedules(in month: Date) async -> [ScheduleItem] {
        let start = month.startOfMonth
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start)!

        let monthKeys = schedulesByDate.keys.filter { $0 >= start && $0 < end }
        let items = monthKeys.flatMap { schedulesByDate[$0] ?? [] }
        let unique = Array(Set(items))

        return unique.sorted { a, b in
            if a.isAllDay != b.isAllDay { return a.isAllDay && !b.isAllDay }
            return a.startDate < b.startDate
        }
    }
}
