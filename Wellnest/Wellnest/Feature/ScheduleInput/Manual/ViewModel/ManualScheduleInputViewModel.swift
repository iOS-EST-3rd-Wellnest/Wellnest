//
//  ManualScheduleInputViewModel.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/16/25.
//

import CoreData

final class ManualScheduleInputViewModel {
    private let store: CoreDataStore           
    private let viewContext: NSManagedObjectContext
    private let notifier: LocalNotifying

    init(store: CoreDataStore,
         viewContext: NSManagedObjectContext,
         notifier: LocalNotifying) {
        self.store = store
        self.viewContext = viewContext
        self.notifier = notifier
    }

    @discardableResult
    func saveSchedule(_ input: ScheduleInput) async throws -> [NSManagedObjectID] {

        let frequency = RepeatRuleParser.frequency(from: input.repeatRuleName)
        let duration = input.endDate.timeIntervalSince(input.startDate)

        let occurrences: [Date] = {
            guard let frequency else {
                return [input.startDate]
            }

            let end = input.hasRepeatEndDate ? input.repeatEndDate : nil

            return RepeatRuleParser.generateOccurrences(start: input.startDate, end: end, frequency: frequency)
        }()

        let seriesId = UUID()
        var createdIDs: [NSManagedObjectID] = []

        for (idx, occStart) in occurrences.enumerated() {
            let occEnd = Date(timeInterval: duration, since: occStart)

            let id = try await store.create(ScheduleEntity.self) { e in
                e.id = UUID()
                e.title = input.title
                e.location = input.location
                e.detail = input.detail
                e.startDate = occStart
                e.endDate = occEnd
                e.isAllDay = input.isAllDay as NSNumber
                e.isCompleted = input.isCompleted as NSNumber
                e.backgroundColor = input.backgroundColorName
                e.repeatRule = input.repeatRuleName
                e.hasRepeatEndDate = input.hasRepeatEndDate
                e.repeatEndDate = input.repeatEndDate
                e.alarm = input.alarmRuleName
                e.scheduleType = "manual"
                e.createdAt = Date()
                e.updatedAt = Date()
                e.seriesId = seriesId
                e.occurrenceIndex = Int64(idx)

                print(e)
            }
            createdIDs.append(id)
        }

        if input.isAlarmOn {
            let idsSnapshot = createdIDs

            await MainActor.run {
                for id in idsSnapshot {
                    if let obj = try? viewContext.existingObject(with: id) as? ScheduleEntity {
                        notifier.scheduleLocalNotification(for: obj)
                    }
                }
            }
        }

        return createdIDs
    }
}

