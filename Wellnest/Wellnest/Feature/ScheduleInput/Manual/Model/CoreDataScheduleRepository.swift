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
    func update(seriesId: UUID, with input: ScheduleInput) async throws -> [NSManagedObjectID]
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
        print(entity)
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
            isCompleted: entity.isCompleted?.boolValue ?? false,
            seriesId: entity.seriesId
        )
    }
    private func apply(_ input: ScheduleInput,
                           to entity: ScheduleEntity,
                           updateDates: Bool = true) {
            entity.title        = input.title
            entity.location     = input.location
            entity.detail       = input.detail

            if updateDates {
                entity.startDate  = input.startDate
                entity.endDate    = input.endDate
            } 

            entity.isAllDay     = NSNumber(value: input.isAllDay)
            entity.isCompleted  = NSNumber(value: input.isCompleted)

            entity.backgroundColor = input.backgroundColorName
            entity.repeatRule      = input.repeatRuleName
            entity.alarm           = input.alarmRuleName

            if input.hasRepeatEndDate {
                entity.hasRepeatEndDate = true
                entity.repeatEndDate    = input.repeatEndDate
            } else {
                entity.hasRepeatEndDate = false
                entity.repeatEndDate    = nil
            }

            entity.updatedAt = Date()
        }

        // MARK: - 시리즈 단위 일괄 업데이트 (날짜 보존)
        func update(seriesId uuid: UUID, with input: ScheduleInput) async throws -> [NSManagedObjectID] {
            try await viewContext.perform {
                let request: NSFetchRequest<ScheduleEntity> = ScheduleEntity.fetchRequest()
                request.predicate = NSPredicate(format: "seriesId == %@", uuid as CVarArg)
                request.includesSubentities = false
                request.returnsObjectsAsFaults = false

                let objs = try self.viewContext.fetch(request)
                guard !objs.isEmpty else { throw ScheduleRepoError.notFound }

                var ids: [NSManagedObjectID] = []
                for obj in objs {
                    self.apply(input, to: obj, updateDates: false)
                    ids.append(obj.objectID)
                }

                if self.viewContext.hasChanges {
                    try self.viewContext.save()
                }
                return ids
            }
        }

        // MARK: - 단일 아이템 업데이트 (날짜 변경 허용)
        func update(id uuid: UUID, with input: ScheduleInput) async throws -> NSManagedObjectID {
            try await viewContext.perform {
                let request: NSFetchRequest<ScheduleEntity> = ScheduleEntity.fetchRequest()
                request.predicate  = NSPredicate(format: "id == %@", uuid as CVarArg)
                request.fetchLimit = 1
                request.includesSubentities = false
                request.returnsObjectsAsFaults = false

                guard let entity = try self.viewContext.fetch(request).first else {
                    throw ScheduleRepoError.notFound
                }

                self.apply(input, to: entity, updateDates: true) // 기본값이므로 생략 가능

                if self.viewContext.hasChanges {
                    try self.viewContext.save()
                }
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
    let seriesId: UUID?
}
