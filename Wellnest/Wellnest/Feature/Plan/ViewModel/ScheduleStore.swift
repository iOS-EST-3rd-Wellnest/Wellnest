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
    struct MonthBucket {
        var items: [ScheduleItem]
        var byDay: [Date: [ScheduleItem]]
        var lastFetched: Date
    }

    @Published private(set) var dayIndex: [Date: [ScheduleItem]] = [:]

    private let calendar = Calendar.current
    private let viewContext: NSManagedObjectContext

    private var monthCache: [Date: MonthBucket] = [:]

    private var objectsDidChangeObserver: NSObjectProtocol?

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        self.viewContext.automaticallyMergesChangesFromParent = true

        objectsDidChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange,
            object: viewContext,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }

            Task { @MainActor in
                self.handleObjectsDidChange(note)
            }
        }
    }

    deinit {
        if let obs = objectsDidChangeObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    func ensureMonthLoaded(_ month: Date) async {
        let key = month.startOfMonth
        if monthCache[key] != nil { return }

        let start = key
        let end = calendar.date(byAdding: .month, value: 1, to: start)!

        let fetched: [ScheduleItem] = await withCheckedContinuation { cont in
            viewContext.perform {
                let items = self.fetchFromCoreData(start: start, end: end)
                cont.resume(returning: items)
            }
        }

        var byDay: [Date: [ScheduleItem]] = [:]
        buildByDay(rangeStart: start, rangeEnd: end, items: fetched, into: &byDay)

        monthCache[key] = MonthBucket(items: fetched, byDay: byDay, lastFetched: .now)

        for (day, list) in byDay { dayIndex[day] = list }

        objectWillChange.send()
    }

    func items(on day: Date) -> [ScheduleItem] {
        dayIndex[day.startOfDay] ?? []
    }

    func hasItems(on day: Date) -> Bool {
        !(dayIndex[day.startOfDay] ?? []).isEmpty
    }

    func items(in month: Date) -> [ScheduleItem] {
        monthCache[month.startOfMonth]?.items ?? []
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
                    eventIdentifier: e.eventIdentifier,
                    location: e.location ?? "",
                    alarm: e.alarm
                )
            }
        } catch {
            print("fetch 실패")
            return []
        }
    }

    private func buildByDay(
        rangeStart: Date,
        rangeEnd: Date,
        items: [ScheduleItem],
        into byDay: inout [Date: [ScheduleItem]]
    ) {
        var currentDay = rangeStart.startOfDay
        while currentDay < rangeEnd {
            byDay[currentDay] = []
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = next
        }

        for item in items {
            let itemStartDay = item.startDate.startOfDay
            let itemEndDay   = item.endDate.startOfDay

            var activeDay = max(itemStartDay, rangeStart.startOfDay)
            let lastDay   = min(itemEndDay, rangeEnd.addingTimeInterval(-1).startOfDay)

            while activeDay <= lastDay {
                byDay[activeDay, default: []].append(item)
                guard let next = calendar.date(byAdding: .day, value: 1, to: activeDay) else { break }
                activeDay = next
            }
        }

        for (day, arr) in byDay {
            byDay[day] = arr.sorted {
                if $0.isAllDay != $1.isAllDay { return $0.isAllDay && !$1.isAllDay }
                return $0.startDate < $1.startDate
            }
        }
    }

    private func handleObjectsDidChange(_ note: Notification) {
        guard let info = note.userInfo else { return }

        let inserted = (info[NSInsertedObjectsKey] as? Set<NSManagedObject>)?
            .compactMap { $0 as? ScheduleEntity } ?? []
        let updated = (info[NSUpdatedObjectsKey] as? Set<NSManagedObject>)?
            .compactMap { $0 as? ScheduleEntity } ?? []
        let deleted = (info[NSDeletedObjectsKey] as? Set<NSManagedObject>)?
            .compactMap { $0 as? ScheduleEntity } ?? []

        if inserted.isEmpty, updated.isEmpty, deleted.isEmpty { return }

        var affectedMonths: Set<Date> = []

        func monthsCovered(by e: ScheduleEntity) -> [Date] {
            guard let s = e.startDate, let t = e.endDate else { return [] }

            var months: [Date] = []
            var cursor = s.startOfMonth
            let endMonth = t.startOfMonth

            while cursor <= endMonth {
                months.append(cursor)
                guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
                cursor = next
            }
            return months
        }

        for e in inserted { monthsCovered(by: e).forEach { affectedMonths.insert($0) } }
        for e in updated  { monthsCovered(by: e).forEach { affectedMonths.insert($0) } }

        if !deleted.isEmpty {
            affectedMonths.formUnion(monthCache.keys.map { $0.startOfMonth })
        } else {
            let changedIDs: Set<UUID> = Set((inserted + updated).compactMap { $0.id })

            if !changedIDs.isEmpty {
                for (monthKey, bucket) in monthCache {
                    if bucket.items.contains(where: { changedIDs.contains($0.id) }) {
                        affectedMonths.insert(monthKey.startOfMonth)
                    }
                }
            }
        }

        if affectedMonths.isEmpty { return }

        for m in affectedMonths {
            if monthCache.removeValue(forKey: m) != nil {
                var day = m.startOfMonth
                let end = calendar.date(byAdding: .month, value: 1, to: day)!
                while day < end {
                    dayIndex.removeValue(forKey: day.startOfDay)
                    guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                    day = next
                }
            }
        }

        Task { [weak self] in
            guard let self else { return }

            await withTaskGroup(of: Void.self) { group in
                for m in affectedMonths {
                    group.addTask { await self.ensureMonthLoaded(m) }
                }
            }
        }
    }
}
