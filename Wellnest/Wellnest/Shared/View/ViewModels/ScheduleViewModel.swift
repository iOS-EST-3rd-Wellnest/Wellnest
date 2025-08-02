//
//  ScheduleViewModel.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import Foundation
import CoreData

final class ScheduleViewModel: ObservableObject {
    @Published var todaySchedules: [ScheduleItem] = []

    func loadTodaySchedules() {
        let (now, endOfDay) = Self.todayBounds()

        let predicate = NSPredicate(
            format: "startDate >= %@ AND startDate <= %@",
            now as NSDate,
            endOfDay as NSDate
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

    // MARK: - Helpers

    private static func todayBounds() -> (Date, Date) {
        let now = Date()
        let calendar = Calendar.current

        // 오늘 자정 (다음 날 00:00:00)
        let startOfTomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)

        // 오늘 밤 11:59:59 (실제로는 자정 바로 직전까지 포함하는 게 안전)
        let endOfToday = calendar.date(byAdding: .second, value: -1, to: startOfTomorrow)!

        return (now, endOfToday)
    }

    private static func mapToItem(entity: ScheduleEntity) -> ScheduleItem {
        ScheduleItem(
            id: entity.id,
            title: entity.title,
            startDate: entity.startDate,
            endDate: entity.endDate
        )
    }
}

struct ScheduleItem: Identifiable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
}
