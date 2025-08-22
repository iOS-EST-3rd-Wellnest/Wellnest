//
//  ScheduleStore.swift
//  Wellnest
//
//  Created by 박동언 on 8/12/25.
//

import SwiftUI
import CoreData

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

//    init() {
//        loadScheduleData()
//    }

//    func scheduleItems(for date: Date) -> [ScheduleItem] {
//        return schedulesByDate[date.startOfDay] ?? []
//    }
//
//    func hasSchedule(for date: Date) -> Bool {
//        return schedulesByDate[date.startOfDay] != nil
//    }

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
    
//    @Published private(set) var schedulesByDate: [Date: [ScheduleItem]] = [:]
//
//        private let calendar = Calendar.current
        private let container: NSPersistentContainer
        private let store: CoreDataStore

        init(container: NSPersistentContainer = CoreDataStack.shared.container) {
            self.container = container
            self.store = CoreDataStore(container: container)

            // 초기 로드
            Task { await reloadFromCoreData() }

            // Core Data 저장 알림 구독 (Combine 없이)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(contextDidSave(_:)),
                name: .NSManagedObjectContextDidSave,
                object: nil
            )
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func scheduleItems(for date: Date) -> [ScheduleItem] {
            schedulesByDate[date.startOfDay] ?? []
        }

        func hasSchedule(for date: Date) -> Bool {
            schedulesByDate[date.startOfDay] != nil
        }

        /// Core Data로부터 모든 앱 일정을 읽어와 날짜별로 버킷팅
        @MainActor
        func reloadFromCoreData() async {
            let sort = NSSortDescriptor(keyPath: \ScheduleEntity.startDate, ascending: true)

            do {
                // 전체 일정 로드 (필요 시 기간 predicate 적용 가능)
                let items = try await store.fetchDTOs(
                    ScheduleEntity.self,
                    predicate: nil,
                    sortDescriptors: [sort]
                ) { e in
                    ScheduleItem(
                        id: e.id ?? UUID(),
                        title: e.title ?? "",
                        startDate: e.startDate ?? Date(),
                        endDate: e.endDate ?? Date(),
                        createdAt: e.createdAt ?? Date(),
                        updatedAt: e.updatedAt ?? Date(),
                        backgroundColor: e.backgroundColor ?? "",
                        isAllDay: e.isAllDay?.boolValue ?? false,
                        repeatRule: e.repeatRule,
                        hasRepeatEndDate: e.hasRepeatEndDate,
                        repeatEndDate: e.repeatEndDate,
                        isCompleted: e.isCompleted?.boolValue ?? false,
                        eventIdentifier: e.eventIdentifier
                    )
                }

                // 날짜별 버킷 생성
                var bucket: [Date: [ScheduleItem]] = [:]
                for item in items {
                    let start = item.startDate.startOfDay
                    let end   = item.endDate.startOfDay

                    var cur = start
                    while cur <= end {
                        var arr = bucket[cur, default: []]
                        arr.append(item)
                        bucket[cur] = arr
                        guard let next = calendar.date(byAdding: .day, value: 1, to: cur) else { break }
                        cur = next
                    }
                }

                // 정렬 (하루 안에서 종일 먼저 → 시작시간 오름차순)
                for (day, arr) in bucket {
                    bucket[day] = arr.sorted { a, b in
                        if a.isAllDay != b.isAllDay { return a.isAllDay && !b.isAllDay }
                        return a.startDate < b.startDate
                    }
                }

                self.schedulesByDate = bucket
            } catch {
                print("📛 ScheduleStore reload 실패:", error.localizedDescription)
            }
        }

        // MARK: - Noti
        @objc private func contextDidSave(_ note: Notification) {
            // 다른 컨텍스트에서 저장되면 viewContext에 merge
            if let ctx = note.object as? NSManagedObjectContext,
               ctx != container.viewContext {
                container.viewContext.mergeChanges(fromContextDidSave: note)
            }
            Task { await reloadFromCoreData() }
        }
}
