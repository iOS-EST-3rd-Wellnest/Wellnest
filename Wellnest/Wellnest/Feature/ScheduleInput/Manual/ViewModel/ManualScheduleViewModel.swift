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
        let calendar = Calendar.current
        let now = Date()

        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        print("📅 오늘 스케줄 로드 - 범위: \(startOfToday) ~ \(startOfTomorrow)")

        let predicate = NSPredicate(
            format: "startDate >= %@ AND startDate < %@",
            startOfToday as NSDate,     // 오늘 00:00부터
            startOfTomorrow as NSDate   // 내일 00:00까지 (오늘 23:59까지)
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
