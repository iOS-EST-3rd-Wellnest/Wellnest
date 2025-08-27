//
//  ScheduleStore.swift
//  Wellnest
//
//  Created by 박동언 on 8/12/25.
//

import SwiftUI
import CoreData

@MainActor
final class ScheduleStore: ObservableObject {
    @Published private(set) var schedulesByDate: [Date: [ScheduleItem]] = [:]

    private let calendar = Calendar.current
    private let viewContext: NSManagedObjectContext

    private var monthCache: [Date: [ScheduleItem]] = [:]

    private var objectsDidChangeObserver: NSObjectProtocol?

    init(context: NSManagedObjectContext) {
        self.viewContext = context

        objectsDidChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange,
            object: viewContext,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }

            Task { @MainActor in
                self.handleObjectsDidChange(notification)
            }
        }
    }

    deinit {
        if let obs = objectsDidChangeObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    func scheduleItems(for date: Date) -> [ScheduleItem] {
        return schedulesByDate[date.startOfDay] ?? []
    }

    func hasSchedule(for date: Date) -> Bool {
        guard let arr = schedulesByDate[date.startOfDay] else { return false }
        return !arr.isEmpty
    }

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

              return entities.compactMap { e in
                  guard let id = e.id,
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
          } catch {
              print(error.localizedDescription)
              return []
          }
      }
    
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

private extension ScheduleStore {
    func handleObjectsDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        let insertedEntities = (userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>)?
            .compactMap { $0 as? ScheduleEntity } ?? []
        let updatedEntities = (userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>)?
            .compactMap { $0 as? ScheduleEntity } ?? []
        let deletedEntities = (userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>)?
            .compactMap { $0 as? ScheduleEntity } ?? []

        if insertedEntities.isEmpty, updatedEntities.isEmpty, deletedEntities.isEmpty { return }

        func monthRange(for entity: ScheduleEntity) -> [Date] {
            guard let startDate = entity.startDate,
                  let endDate = entity.endDate else { return [] }

            var months: Set<Date> = []
            var currentMonth = startDate.startOfMonth
            let lastMonth = endDate.startOfMonth

            while currentMonth <= lastMonth {
                months.insert(currentMonth)
                guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) else { break }
                currentMonth = nextMonth
            }
            return Array(months)
        }

        let affectedMonths = (insertedEntities + updatedEntities + deletedEntities)
            .flatMap { monthRange(for: $0) }
            .map { $0.startOfMonth }

        let uniqueAffectedMonths = Set(affectedMonths)

        for monthStart in uniqueAffectedMonths {
            monthCache[monthStart] = nil
            Task { [weak self] in
                _ = await self?.fetchSchedules(in: monthStart)
            }
        }
    }
}
