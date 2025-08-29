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

    private let service: CoreDataService

    init(service: CoreDataService = .shared) {
        self.service = service
    }

    // MARK: - Load
    /// 오늘 날짜에 해당하는 일정 목록 조회하여 todaySchedules에 초기화
    func loadTodaySchedules() {
        Task { await loadTodaySchedules() } // async 버전 재사용
    }

    @MainActor
    private func loadTodaySchedules() async {
        let (now, startOfTomorrow) = Self.todayBounds()

        let predicate = NSPredicate(
            format: "endDate != nil AND endDate > %@ AND startDate < %@",
            now as NSDate,
            startOfTomorrow as NSDate
        )
        let sort = [
            NSSortDescriptor(keyPath: \ScheduleEntity.startDate, ascending: true),
            NSSortDescriptor(keyPath: \ScheduleEntity.endDate,   ascending: true)
        ]

        do {
            let entities: [ScheduleEntity] = try service.fetch(
                ScheduleEntity.self,
                predicate: predicate,
                sortDescriptors: sort
            )

            let items = entities.map { e in
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
                    eventIdentifier: nil,
                    location: e.location ?? "",
                    alarm: e.alarm
                )
            }
            self.todaySchedules = items
        } catch {
            print("📛 일정 로드 실패:", error.localizedDescription)
        }
    }

    // MARK: - Update Completed
    /// 일정 완료 상태 토글
    func updateCompleted(item: ScheduleItem) {
        Task { await updateCompleted(item: item) } // async 버전 재사용
    }

    @MainActor
    private func updateCompleted(item: ScheduleItem) async {
        let predicate = NSPredicate(format: "id == %@", item.id as CVarArg)

        do {
            let entities: [ScheduleEntity] = try service.fetch(
                ScheduleEntity.self,
                predicate: predicate,
                sortDescriptors: nil
            )
            guard let entity = entities.first else {
                print("📛 대상 일정 ID 조회 실패")
                return
            }

            let current = entity.isCompleted?.boolValue ?? false
            entity.isCompleted = NSNumber(value: !current)
            entity.updatedAt = Date()

            try service.saveContext()

            if let idx = self.todaySchedules.firstIndex(where: { $0.id == item.id }) {
                self.todaySchedules[idx].isCompleted.toggle()
            }
        } catch {
            print("❌ 일정 완료 토글 실패:", error.localizedDescription)
        }
    }

    // MARK: - Delete
    /// 일정 삭제
    func deleteSchedule(item: ScheduleItem) {
        Task { await deleteSchedule(item: item) } // async 버전 재사용
    }

    @MainActor
    private func deleteSchedule(item: ScheduleItem) async {
        let predicate = NSPredicate(format: "id == %@", item.id as CVarArg)

        do {
            let entities: [ScheduleEntity] = try service.fetch(
                ScheduleEntity.self,
                predicate: predicate,
                sortDescriptors: nil
            )
            guard let entity = entities.first else {
                print("📛 대상 일정 ID 조회 실패")
                return
            }

            try service.delete(entity)
            self.todaySchedules.removeAll { $0.id == item.id }
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
        let service = CoreDataService.shared
        return ManualScheduleViewModel(service: service)
    }
}
