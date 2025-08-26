//
//  CoreDataScheduleRepository.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/26/25.
//

import Foundation
import CoreData
import SwiftUI

protocol ScheduleRepository {
    func create(with input: ScheduleInput) async throws -> [NSManagedObjectID]
//    func fetch(by id: NSManagedObjectID) async throws -> ScheduleSnapshot
//    func update(id: NSManagedObjectID, with input: ScheduleInput) async throws -> NSManagedObjectID
    func fetch(by id: UUID) async throws -> ScheduleSnapshot
    func update(id: UUID, with input: ScheduleInput) async throws -> NSManagedObjectID
    func delete(id: NSManagedObjectID) async throws
}

enum ScheduleRepoError: Error {
    case notFound
    case invalid(String)
    case underlying(Error)
}

class CoreDataScheduleRepository: ScheduleRepository {
    private let store: CoreDataStore
    private let viewContext: NSManagedObjectContext
    private let notifier: LocalNotifying?

    init(
        store: CoreDataStore,
        viewContext: NSManagedObjectContext,
        notifier: LocalNotifying?
    ) {
        self.store = store
        self.viewContext = viewContext
        self.notifier = notifier
    }

    func create(with input: ScheduleInput) async throws -> [NSManagedObjectID] {
        let frequency = RepeatRuleParser.frequency(from: input.repeatRuleName)
        let duration = input.endDate.timeIntervalSince(input.startDate)

        let occurrences: [Date] = {
            guard let frequency else { return [input.startDate] }
            let end = input.hasRepeatEndDate ? input.repeatEndDate : nil
            return RepeatRuleParser.generateOccurrences(start: input.startDate, end: end, frequency: frequency)
        }()

        let seriesId = UUID()
        var createdIds: [NSManagedObjectID] = []

        for (index, occurrenceStart) in occurrences.enumerated() {
            let occurrenceEnd = Date(timeInterval: duration, since: occurrenceStart)
            let id = try await store.create(ScheduleEntity.self) { entity in
                entity.id = UUID()
                entity.title = input.title
                entity.location = input.location
                entity.detail = input.detail
                entity.startDate = occurrenceStart
                entity.endDate = occurrenceEnd
                entity.isAllDay = NSNumber(value: input.isAllDay)
                entity.isCompleted = NSNumber(value: input.isCompleted)
                entity.backgroundColor = input.backgroundColorName
                entity.repeatRule = input.repeatRuleName
                entity.hasRepeatEndDate = input.hasRepeatEndDate
                entity.repeatEndDate = input.repeatEndDate
                entity.alarm = input.alarmRuleName
                entity.scheduleType = "manual"
                entity.createdAt = Date()
                entity.updatedAt = Date()
                entity.seriesId = seriesId
                entity.occurrenceIndex = Int64(index)
            }
            createdIds.append(id)
        }

        if input.isAlarmOn, let notifier {
            let idsSnapshot = createdIds
            await MainActor.run {
                for id in idsSnapshot {
                    if let obj = try? viewContext.existingObject(with: id) as? ScheduleEntity {
                        notifier.scheduleLocalNotification(for: obj)
                    }
                }
            }
        }
        return createdIds
    }

    func fetch(by uuid: UUID) async throws -> ScheduleSnapshot {
        let request: NSFetchRequest<ScheduleEntity> = ScheduleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        request.fetchLimit = 1

        guard let entity = try viewContext.fetch(request).first else {
            throw NSError(domain: "Repository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])
        }
        return ScheduleSnapshot(
            id: entity.objectID,
            title: entity.title ?? "",
            location: entity.location ?? "",
            detail: entity.detail ?? "",
            startDate: entity.startDate ?? Date(),
            endDate: entity.endDate ?? Date(),
            isAllDay: entity.isAllDay?.boolValue ?? false,
            backgroundColorName: entity.backgroundColor ?? "wellnestBlue",
            repeatRuleName: entity.repeatRule,
            repeatEndDate: entity.hasRepeatEndDate ? entity.repeatEndDate : nil,
            alarmRuleName: entity.alarm,
            isAlarmOn: entity.alarm != nil,
            isCompleted: entity.isCompleted?.boolValue ?? false
        )
    }


    func update(id uuid: UUID, with input: ScheduleInput) async throws -> NSManagedObjectID {
        try await viewContext.perform { [self] in
            let request: NSFetchRequest<ScheduleEntity> = ScheduleEntity.fetchRequest()
            request.predicate = NSPredicate(format: "uuid == %@", uuid as CVarArg)
            request.fetchLimit = 1

            guard let entity = try self.viewContext.fetch(request).first else {
                throw ScheduleRepoError.notFound
            }

            entity.title = input.title
            entity.location = input.location
            entity.detail = input.detail
            entity.startDate = input.startDate
            entity.endDate = input.endDate
            entity.isAllDay = NSNumber(value: input.isAllDay)
            entity.isCompleted = NSNumber(value: input.isCompleted)
            entity.backgroundColor = input.backgroundColorName
            entity.repeatRule = input.repeatRuleName
            entity.hasRepeatEndDate = input.hasRepeatEndDate
            entity.repeatEndDate = input.repeatEndDate
            entity.alarm = input.alarmRuleName
            entity.updatedAt = Date()

            try viewContext.save()
            return entity.objectID
        }
    }

    func delete(id: NSManagedObjectID) async throws {
        try await viewContext.perform {
            guard let e = try? self.viewContext.existingObject(with: id) as? ScheduleEntity else {
                throw ScheduleRepoError.notFound
            }
            self.viewContext.delete(e)
            try self.viewContext.save()
        }
    }

}

struct ScheduleSnapshot {
    let id: NSManagedObjectID
    let title: String
    let location: String
    let detail: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let backgroundColorName: String
    let repeatRuleName: String?     
    let repeatEndDate: Date?
    let alarmRuleName: String?
    let isAlarmOn: Bool
    let isCompleted: Bool
}
