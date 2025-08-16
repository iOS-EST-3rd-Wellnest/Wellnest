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
        Task { await loadTodaySchedules() } // 위의 async 버전을 재사용
    }

    private func loadTodaySchedules() async {
        let (now, startOfTomorrow) = Self.todayBounds()

        let predicate = NSPredicate(
            format: "endDate != nil AND endDate > %@ AND startDate < %@",
            now as NSDate,
            startOfTomorrow as NSDate
        )
        let sort = NSSortDescriptor(keyPath: \ScheduleEntity.startDate, ascending: true)

        do {
            // actor 내부에서 Entity -> DTO 변환
            let items = try await store.fetchDTOs(
                ScheduleEntity.self,
                predicate: predicate,
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
                    isCompleted: e.isCompleted?.boolValue ?? false
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
            let ids = try await store.fetchIDs(ScheduleEntity.self, predicate: predicate, sortDescriptors: nil, fetchLimit: 1)
            guard let objectID = ids.first else {
                print("📛 대상 일정 ID 조회 실패")
                return
            }

            try await store.update(id: objectID) { (e: ScheduleEntity) in
                let current = e.isCompleted?.boolValue ?? false
                e.isCompleted = NSNumber(value: !current)
                e.updatedAt = Date()
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
            let ids = try await store.fetchIDs(ScheduleEntity.self, predicate: predicate, sortDescriptors: nil, fetchLimit: 1)
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
