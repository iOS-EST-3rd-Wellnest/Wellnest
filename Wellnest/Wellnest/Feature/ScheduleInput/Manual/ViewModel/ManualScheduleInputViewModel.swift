//
//  ManualScheduleInputViewModel.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/16/25.
//

import CoreData

final class ManualScheduleInputViewModel {
    private let service: CoreDataService
    private let notifier: LocalNotifying

    init(service: CoreDataService = .shared,
         notifier: LocalNotifying) {
        self.service = service
        self.notifier = notifier
    }

    @discardableResult
    func saveSchedule(_ input: ScheduleInput) async throws -> [NSManagedObjectID] {
        // 반복 규칙 전개 준비
        let frequency = RepeatRuleParser.frequency(from: input.repeatRuleName)
        let duration = input.endDate.timeIntervalSince(input.startDate)

        let occurrences: [Date] = {
            guard let frequency else { return [input.startDate] }
            let end = input.hasRepeatEndDate ? input.repeatEndDate : nil
            return RepeatRuleParser.generateOccurrences(
                start: input.startDate,
                end: end,
                frequency: frequency
            )
        }()

        let seriesId = UUID()
        var created: [ScheduleEntity] = []
        created.reserveCapacity(occurrences.count)

        // 엔티티 생성
        for (idx, occStart) in occurrences.enumerated() {
            let occEnd = Date(timeInterval: duration, since: occStart)

            let e: ScheduleEntity = service.create(ScheduleEntity.self)
            e.id               = UUID()
            e.title            = input.title
            e.location         = input.location
            e.detail           = input.detail
            e.startDate        = occStart
            e.endDate          = occEnd
            e.isAllDay         = NSNumber(value: input.isAllDay)
            e.isCompleted      = NSNumber(value: input.isCompleted)
            e.backgroundColor  = input.backgroundColorName
            e.repeatRule       = input.repeatRuleName
            e.hasRepeatEndDate = input.hasRepeatEndDate
            e.repeatEndDate    = input.repeatEndDate
            e.alarm            = input.alarmRuleName
            e.scheduleType     = "manual"
            e.createdAt        = Date()
            e.updatedAt        = Date()
            e.seriesId         = seriesId
            e.occurrenceIndex  = Int64(idx)

            created.append(e)
        }

        // 저장
        try service.saveContext()

        // 로컬 알림 예약
        if input.isAlarmOn {
            for obj in created {
                notifier.scheduleLocalNotification(for: obj)
            }
        }

        return created.map { $0.objectID }
    }
}

