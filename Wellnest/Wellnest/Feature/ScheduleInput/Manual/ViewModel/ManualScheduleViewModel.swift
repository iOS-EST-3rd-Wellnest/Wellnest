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

    // MARK: - Helpers

    private static func todayBounds() -> (Date, Date) {
        let now = Date()
        let calendar = Calendar.current

        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        return (now, startOfTomorrow)
    }

    private static func mapToItem(entity: ScheduleEntity) -> ScheduleItem {
        ScheduleItem(
            id: entity.id ?? UUID(),
            title: entity.title ?? "",
            startDate: entity.startDate ?? Date(),
            endDate: entity.endDate ?? Date()
        )
    }
}
