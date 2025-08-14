//
//  ScheduleStore.swift
//  Wellnest
//
//  Created by 박동언 on 8/12/25.
//

import SwiftUI

enum RepeatFrequency: String, Codable {
    case daily = "매일"
    case weekly = "매주"
    case monthly = "매월"
    case yearly = "매년"
}

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
}
