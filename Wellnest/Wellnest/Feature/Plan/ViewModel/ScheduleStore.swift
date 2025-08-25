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
            rebuildSchedulesByDate(for: monthStart, rangeEnd: monthEnd, items: fetched)
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
    private func rebuildSchedulesByDate(for rangeStart: Date,
                                        rangeEnd: Date,
                                        items: [ScheduleItem]) {
        var schedulesByDay: [Date: [ScheduleItem]] = [:]

        var currentDay = rangeStart.startOfDay
        while currentDay < rangeEnd {
            schedulesByDay[currentDay] = []
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = nextDay
        }

        for item in items {
            let itemStartDay = item.startDate.startOfDay
            let itemEndDay = item.endDate.startOfDay

            var activeDay = max(itemStartDay, rangeStart.startOfDay)
            let lastDay = min(itemEndDay, rangeEnd.addingTimeInterval(-1).startOfDay)

            while activeDay <= lastDay {
                schedulesByDay[activeDay, default: []].append(item)
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: activeDay) else { break }
                activeDay = nextDay
            }
        }

        for (day, daySchedules) in schedulesByDay {
            schedulesByDay[day] = daySchedules.sorted {
                if $0.isAllDay != $1.isAllDay {
                    return $0.isAllDay && !$1.isAllDay
                }
                return $0.startDate < $1.startDate
            }
        }

        for (day, schedules) in schedulesByDay {
            schedulesByDate[day] = schedules
        }
    }
}
