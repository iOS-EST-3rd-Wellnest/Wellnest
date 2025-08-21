//
//  ScheduleViewModel.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import Foundation
import CoreData

final class ManualScheduleViewModel: ObservableObject {
    @Published var todaySchedules: [ScheduleItem] = []

    private let store: CoreDataStore

    init(store: CoreDataStore) {
        self.store = store
    }

    // MARK: - Load
    /// 오늘 날짜에 해당하는 일정 목록 조회하여 todaySchedules에 초기화
    func loadTodaySchedules() {
        Task { await loadTodaySchedulesAdvanced() } // 위의 async 버전을 재사용
    }

    private func loadTodaySchedulesAdvanced() async {
        let (now, startOfTomorrow) = Self.todayBounds()

        let predicate = NSPredicate(
            format: "endDate != nil AND endDate > %@ AND startDate < %@",
            now as NSDate,
            startOfTomorrow as NSDate
        )
        let sort = NSSortDescriptor(keyPath: \EventSeriesEntity.startDate, ascending: true)

        do {
            // actor 내부에서 Entity -> DTO 변환
            let items = try await store.fetchDTOs(
                EventSeriesEntity.self,
                predicate: predicate,
                sortDescriptors: [sort]
            ) { seriesEntity in
                ScheduleItem(
                    id: seriesEntity.id ?? UUID(),
                    title: seriesEntity.title ?? "",
                    startDate: seriesEntity.startDate ?? Date(),
                    endDate: seriesEntity.endDate ?? Date(),
                    createdAt: Date(),
                    updatedAt: Date(),
                    backgroundColor: seriesEntity.colorName ?? "",
                    isAllDay: seriesEntity.isAllDay,
                    repeatRule: seriesEntity.recurrenceRule?.frequency,
                    hasRepeatEndDate: seriesEntity.recurrenceRule?.until != nil,
                    repeatEndDate: seriesEntity.recurrenceRule?.until,
                    isCompleted: seriesEntity.isCompleted,
                    eventIdentifier: nil
                )
            }
            await MainActor.run {
                self.todaySchedules = items
            }
        } catch {
            print("📛 일정 로드 실패:", error.localizedDescription)
        }
    }

    // MARK: - Update Completed
    /// 일정 완료 상태 토글
    func updateCompleted(item: ScheduleItem) {
        Task { await updateCompleted(item: item) } // 위의 async 버전을 재사용
    }

    private func updateCompleted(item: ScheduleItem) async {
        // UUID로 해당 엔티티의 ObjectID 조회
        let predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        do {
            let ids = try await store.fetchIDs(EventSeriesEntity.self, predicate: predicate, sortDescriptors: nil, fetchLimit: 1)
            guard let objectID = ids.first else {
                print("📛 대상 일정 ID 조회 실패")
                return
            }

            try await store.update(id: objectID) { (e: EventSeriesEntity) in
                let current = e.isCompleted
                e.isCompleted = true
            }
            await MainActor.run {
                if let idx = self.todaySchedules.firstIndex(where: { $0.id == item.id }) {
                    self.todaySchedules[idx].isCompleted.toggle()
                }
            }
        } catch {
            print("❌ 일정 완료 토글 실패:", error.localizedDescription)
        }
    }

    // MARK: - Delete
    /// 일정 삭제
    func deleteSchedule(item: ScheduleItem) {
        Task { await deleteSchedule(item: item) } // 위의 async 버전을 재사용
    }

    func deleteSchedule(item: ScheduleItem) async {
        let predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        do {
            let ids = try await store.fetchIDs(EventSeriesEntity.self, predicate: predicate, sortDescriptors: nil, fetchLimit: 1)
            guard let objectID = ids.first else {
                print("📛 대상 일정 ID 조회 실패")
                return
            }

            try await store.delete(id: objectID)
            await MainActor.run {
                self.todaySchedules.removeAll { $0.id == item.id }
            }
        } catch {
            print("❌ 일정 삭제 실패:", error.localizedDescription)
        }
    }

    // MARK: - Helpers
    private static func todayBounds() -> (Date, Date) {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        return (now, startOfTomorrow)
    }
}


enum ManualScheduleVMFactory {
    static func make() -> ManualScheduleViewModel {
        let container = CoreDataStack.shared.container
        let store = CoreDataStore(container: container)
        return ManualScheduleViewModel(store: store)
    }
}
