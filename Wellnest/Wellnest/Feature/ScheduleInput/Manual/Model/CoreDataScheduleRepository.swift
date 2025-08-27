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
    func delete(id: UUID) async throws
    func deleteAll(seriesId: UUID) async throws -> [NSManagedObjectID]
    func deleteSeriesOccurrences(seriesId: UUID, after anchor: Date, includeAnchor: Bool) async throws
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
        let predicate = NSPredicate(format: "id == %@", uuid as CVarArg)

        let snaps: [ScheduleSnapshot] = try await store.fetchDTOs(
            ScheduleEntity.self,
            predicate: predicate
        ) { e in
            ScheduleSnapshot(
                id: e.objectID,
                title: e.title ?? "",
                location: e.location ?? "",
                detail: e.detail ?? "",
                startDate: e.startDate ?? Date(),
                endDate: e.endDate ?? Date(),
                isAllDay: e.isAllDay?.boolValue ?? false,
                backgroundColorName: e.backgroundColor ?? "wellnestBlue",
                repeatRuleName: e.repeatRule,
                repeatEndDate: e.hasRepeatEndDate ? e.repeatEndDate : nil,
                alarmRuleName: e.alarm,
                isAlarmOn: e.alarm != nil,
                isCompleted: e.isCompleted?.boolValue ?? false,
                seriesId: e.seriesId
            )
        }

        guard let snap = snaps.first else { throw ScheduleRepoError.notFound }
        return snap
    }

    private func apply(
        _ input: ScheduleInput,
        to entity: ScheduleEntity,
        updateDates: Bool
    ) {
        entity.title      = input.title
        entity.location   = input.location
        entity.detail     = input.detail
        
        if updateDates {
            entity.startDate = input.startDate
            entity.endDate   = input.endDate
        }
        
        entity.isAllDay = NSNumber(value: input.isAllDay)
        entity.isCompleted = NSNumber(value: input.isCompleted)
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

    // MARK: - 단일 아이템 업데이트 (날짜 포함 갱신)
    func update(id uuid: UUID, with input: ScheduleInput) async throws -> NSManagedObjectID {
        let ids = try await store.fetchIDs(
            ScheduleEntity.self,
            predicate: NSPredicate(format: "id == %@", uuid as CVarArg),
            fetchLimit: 1
        )
        guard let oid = ids.first else { throw ScheduleRepoError.notFound }

        try await store.update(id: oid) { (obj: ScheduleEntity) in
            self.apply(input, to: obj, updateDates: true)
        }
        return oid
    }

    // MARK: - 시리즈 단위 일괄 업데이트 (start/end 보존)
    func update(seriesId uuid: UUID, with input: ScheduleInput) async throws -> [NSManagedObjectID] {
        let ids = try await store.fetchIDs(
            ScheduleEntity.self,
            predicate: NSPredicate(format: "seriesId == %@", uuid as CVarArg)
        )
        guard !ids.isEmpty else { throw ScheduleRepoError.notFound }

        for oid in ids {
            try await store.update(id: oid) { (obj: ScheduleEntity) in
                self.apply(input, to: obj, updateDates: false)
            }
        }
        return ids
    }
    
    // MARK: - UUID로 단일 삭제
    func delete(id: UUID) async throws {
        let ids = try await store.fetchIDs(
            ScheduleEntity.self,
            predicate: NSPredicate(format: "id == %@", id as CVarArg),
            fetchLimit: 1
        )
        guard let oid = ids.first else {
            throw ScheduleRepoError.notFound
        }

        try await store.delete(id: oid)
    }


    // MARK: - 시리즈 단위 일괄 삭제
    func deleteAll(seriesId uuid: UUID) async throws -> [NSManagedObjectID] {
        // 1. 해당 seriesId를 가진 모든 엔티티의 objectID 가져오기
        let ids = try await store.fetchIDs(
            ScheduleEntity.self,
            predicate: NSPredicate(format: "seriesId == %@", uuid as CVarArg)
        )
        guard !ids.isEmpty else {
            throw ScheduleRepoError.notFound
        }

        // 2. 반복문 돌면서 하나씩 삭제
        for oid in ids {
            try await store.delete(id: oid)
        }

        // 3. 삭제한 objectID 배열 리턴
        return ids
    }

    func deleteSeriesOccurrences(seriesId: UUID,
                                 after anchor: Date,
                                 includeAnchor: Bool) async throws {
        let op = includeAnchor ? ">=" : ">"
        let predicate = NSPredicate(
            format: "seriesId == %@ AND startDate \(op) %@",
            seriesId as CVarArg, anchor as CVarArg
        )

        // IDs만 가져와서
        let ids = try await store.fetchIDs(ScheduleEntity.self, predicate: predicate)

        // 개별 삭제
        for id in ids {
            try await store.delete(id: id)
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
