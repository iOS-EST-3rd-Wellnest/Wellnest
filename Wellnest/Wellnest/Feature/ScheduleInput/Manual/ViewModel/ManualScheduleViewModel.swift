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
    
    /// 오늘 날짜에 해당하는 일정 목록 조회하여 todaySchedules에 초기화
    func loadTodaySchedules() {
        let (now, startOfTomorrow) = Self.todayBounds()

        let predicate = NSPredicate(
            format: "endDate != nil AND endDate > %@ AND startDate < %@",
            now as NSDate,
            startOfTomorrow as NSDate
        )


        let sort = NSSortDescriptor(keyPath: \ScheduleEntity.startDate, ascending: true)

        do {
            let entities = try CoreDataService.shared.fetch(
                ScheduleEntity.self,
                predicate: predicate,
                sortDescriptors: [sort]
            )

            todaySchedules = entities.map(Self.mapToItem)
        } catch {
            print("📛 일정 로드 실패:", error.localizedDescription)
        }
    }
    
    /// 일정 완료 상태 변경
    /// - Parameter item: 완료 상태를 변경하려는 ScheduleItem
    func updateCompleted(item: ScheduleItem) {
        guard let entity = fetchSchedule(id: item.id) else {
            print("📛 대상 일정 entity fetch 실패")
            return
        }
        
        do {
            try CoreDataService.shared.update(entity, by: \ScheduleEntity.isCompleted, to: !entity.isCompleted)
            if let index = todaySchedules.firstIndex(where: { $0.id == item.id }) {
                todaySchedules[index].isCompleted.toggle()
            }
        } catch {
            print("❌ 일정 삭제 실패:", error.localizedDescription)
        }
    }
    
    /// 일정 삭제
    /// - Parameter item: 삭제하려는 일정 ScheduleItem
    func deleteSchedule(item: ScheduleItem) {
        guard let entity = fetchSchedule(id: item.id) else {
            print("📛 대상 일정 entity fetch 실패")
            return
        }

        do {
            try CoreDataService.shared.delete(entity)
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

    /// ScheduleItem 객체 생성
    /// - Parameter entity: ScheduleItem 객체로 생성할 데이터로 ScheduleEntity를 파라미터로 받음
    /// - Returns: 생성된 ScheduleItem 리턴
    private static func mapToItem(entity: ScheduleEntity) -> ScheduleItem {
        ScheduleItem(
            id: entity.id ?? UUID(),
            title: entity.title ?? "",
            startDate: entity.startDate ?? Date(),
            endDate: entity.endDate ?? Date(),
            isCompleted: entity.isCompleted
        )
    }
    
    /// id를 활용하여 일정 조회
    /// - Parameter id: 조회하려는 id
    /// - Returns: 조회한 ScheduleEntity
    private func fetchSchedule(id: ScheduleItem.ID) -> ScheduleEntity? {
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let entity = try CoreDataService.shared.fetch(ScheduleEntity.self, predicate: predicate)
            return entity.first
        } catch {
            print("📛 대상 일정 fetch 실패:", error.localizedDescription)
            return nil
        }
    }
}
