//
//  ScheduleStore.swift
//  Wellnest
//
//  Created by 박동언 on 8/12/25.
//

import SwiftUI
import CoreData

final class ScheduleStore: ObservableObject {
    @Published private(set) var schedulesByDate: [Date: [ScheduleItem]] = [:]

    private let calendar = Calendar.current
    private let viewContext: NSManagedObjectContext

    private var monthCache: [Date: [ScheduleItem]] = [:]

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    func scheduleItems(for date: Date) -> [ScheduleItem] {
        return schedulesByDate[date.startOfDay] ?? []
    }

    func hasSchedule(for date: Date) -> Bool {
        guard let arr = schedulesByDate[date.startOfDay] else { return false }
        return !arr.isEmpty
    }

    @MainActor
    func fetchSchedules(in month: Date) async -> [ScheduleItem] {
        let monthStart = month.startOfMonth
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

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

        return monthCache[monthStart] ?? []
    }

    private func fetchFromCoreData(start: Date, end: Date) -> [ScheduleItem] {
          let request: NSFetchRequest<ScheduleEntity> = ScheduleEntity.fetchRequest()
          request.predicate = NSPredicate(
              format: "startDate < %@ AND endDate > %@",
              end as NSDate, start as NSDate
          )
          request.sortDescriptors = [
              NSSortDescriptor(key: #keyPath(ScheduleEntity.startDate), ascending: true)
          ]

          do {
              let entities = try viewContext.fetch(request)

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

        return slices.sorted { a, b in
            if a.isAllDayForThatDate != b.isAllDayForThatDate { return a.isAllDayForThatDate }
            switch (a.displayStart, b.displayStart) {
            case let (sa?, sb?): return sa < sb
            case (nil, _?): return true
            case (_?, nil): return false
            default: return false
            }
        }
    }
}
