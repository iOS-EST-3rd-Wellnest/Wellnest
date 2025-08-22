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

        if monthCache[monthStart] == nil {
            let fetched = fetchFromCoreData(start: monthStart, end: monthEnd)
            monthCache[monthStart] = fetched
            rebuildSchedulesByDate(for: monthStart, end: monthEnd, items: fetched)
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

              let items: [ScheduleItem] = entities.compactMap { e -> ScheduleItem? in
                  guard
                      let id = e.id,
                      let title = e.title,
                      let startDate = e.startDate,
                      let endDate = e.endDate,
                      let createdAt = e.createdAt,
                      let updatedAt = e.updatedAt,
                      let bg = e.backgroundColor
                  else { return nil }

                  return ScheduleItem(
                      id: id,
                      title: title,
                      startDate: startDate,
                      endDate: endDate,
                      createdAt: createdAt,
                      updatedAt: updatedAt,
                      backgroundColor: bg,
                      isAllDay: e.isAllDay?.boolValue ?? false,
                      repeatRule: e.repeatRule,
                      hasRepeatEndDate: e.hasRepeatEndDate,
                      repeatEndDate: e.repeatEndDate,
                      isCompleted: e.isCompleted?.boolValue ?? false,
                      eventIdentifier: e.eventIdentifier
                  )
              }

              return items
          } catch {
              print(error.localizedDescription)
              return []
          }
      }
    
    @MainActor
    private func rebuildSchedulesByDate(for start: Date, end: Date, items: [ScheduleItem]) {
        var dict: [Date: [ScheduleItem]] = [:]

        var day = start.startOfDay
        while day < end {
            dict[day] = []
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        for item in items {
            let s = item.startDate.startOfDay
            let e = item.endDate.startOfDay

            var cur = max(s, start.startOfDay)
            let last = min(e, end.addingTimeInterval(-1).startOfDay)

            while cur <= last {
                dict[cur, default: []].append(item)
                guard let next = calendar.date(byAdding: .day, value: 1, to: cur) else { break }
                cur = next
            }
        }

        for (k, arr) in dict {
            dict[k] = arr.sorted {
                if $0.isAllDay != $1.isAllDay { return $0.isAllDay && !$1.isAllDay }
                return $0.startDate < $1.startDate
            }
        }

        for (k, v) in dict {
            schedulesByDate[k] = v
        }
    }
}

struct ScheduleDaySlice: Identifiable {
    let id = UUID()
    let item: ScheduleItem
    let date: Date
    let displayStart: Date?
    let displayEnd: Date?
    let isAllDayForThatDate: Bool
}

extension ScheduleStore {
    func daySlices(for date: Date) -> [ScheduleDaySlice] {
        let cal = Calendar.current
        let day = date.startOfDay
        let nextDay = cal.date(byAdding: .day, value: 1, to: day)!
        let items = schedulesByDate[day] ?? []

        let slices = items.map { item -> ScheduleDaySlice in
            if item.isAllDay {
                return .init(item: item, date: day, displayStart: nil, displayEnd: nil, isAllDayForThatDate: true)
            }
            if item.startDate <= day && item.endDate >= nextDay {
                return .init(item: item, date: day, displayStart: nil, displayEnd: nil, isAllDayForThatDate: true)
            }
            let start = max(item.startDate, day)
            let end = min(item.endDate, nextDay)
            return .init(item: item, date: day, displayStart: start, displayEnd: end, isAllDayForThatDate: false)
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
