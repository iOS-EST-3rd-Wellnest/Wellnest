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

        // 월 캐시에 없으면 Core Data에서 로드
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
                  // 필수값 unwrap
                  guard
                      let id = e.id,
                      let title = e.title,
                      let startDate = e.startDate,
                      let endDate = e.endDate,
                      let createdAt = e.createdAt,
                      let updatedAt = e.updatedAt,
                      let bg = e.backgroundColor
                  else { return nil }

                  // 프로젝트의 Core Data 모델이 Bool/UUID/Int32 실타입이라고 가정
                  return ScheduleItem(
                      id: id,
                      title: title,
                      startDate: startDate,
                      endDate: endDate,
                      createdAt: createdAt,
                      updatedAt: updatedAt,
                      backgroundColor: bg,
                      isAllDay: e.isAllDay?.boolValue ?? false,
                      repeatRule: e.repeatRule,               // 저장 시 개별 확장했어도 원문 보존용으로 유지 가능
                      hasRepeatEndDate: e.hasRepeatEndDate,
                      repeatEndDate: e.repeatEndDate,
                      isCompleted: e.isCompleted?.boolValue ?? false,
                      eventIdentifier: e.eventIdentifier       // 모델에 있다면 매핑
                  )
              }

              return items
          } catch {
              print("❌ CoreData fetch failed:", error.localizedDescription)
              return []
          }
      }

    private func rebuildSchedulesByDate(for start: Date, end: Date, items: [ScheduleItem]) {
        var dict: [Date: [ScheduleItem]] = [:]

        // 1) 월 범위 날짜 키 초기화
        var day = start.startOfDay
        while day < end {
            dict[day] = []
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        // 2) 각 아이템을 날짜별로 분배 (start~end span 포함)
        for item in items {
            let s = item.startDate.startOfDay
            let e = item.endDate.startOfDay

            // 월 범위를 벗어나는 경우를 고려하여 clamp
            var cur = max(s, start.startOfDay)
            let last = min(e, end.addingTimeInterval(-1).startOfDay)

            while cur <= last {
                dict[cur, default: []].append(item)
                guard let next = calendar.date(byAdding: .day, value: 1, to: cur) else { break }
                cur = next
            }
        }

        // 3) 정렬: all-day 우선 → 시작시간
        for (k, arr) in dict {
            dict[k] = arr.sorted {
                if $0.isAllDay != $1.isAllDay { return $0.isAllDay && !$1.isAllDay }
                return $0.startDate < $1.startDate
            }
        }

        // 4) 해당 월 범위만 갱신
        for (k, v) in dict {
            schedulesByDate[k] = v
        }
    }
}
