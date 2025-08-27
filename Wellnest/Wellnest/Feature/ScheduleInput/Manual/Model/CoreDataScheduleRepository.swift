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

final class CoreDataScheduleRepository: ScheduleRepository {
    private let service: CoreDataService
    private let notifier: LocalNotifying?

    init(service: CoreDataService = .shared, notifier: LocalNotifying?) {
        self.service = service
        self.notifier = notifier
    }

    // MARK: - Create
    @MainActor
    func create(with input: ScheduleInput) async throws -> [NSManagedObjectID] {
        let frequency = RepeatRuleParser.frequency(from: input.repeatRuleName)
        let duration = input.endDate.timeIntervalSince(input.startDate)

        let occurrences: [Date] = {
            guard let frequency else { return [input.startDate] }
            let end = input.hasRepeatEndDate ? input.repeatEndDate : nil
            return RepeatRuleParser.generateOccurrences(start: input.startDate,
                                                        end: end,
                                                        frequency: frequency)
        }()

        let seriesId = UUID()
        var created: [ScheduleEntity] = []
        created.reserveCapacity(occurrences.count)

        for (index, occurrenceStart) in occurrences.enumerated() {
            let occurrenceEnd = Date(timeInterval: duration, since: occurrenceStart)
            let e: ScheduleEntity = service.create(ScheduleEntity.self)
            e.id                = UUID()
            e.title             = input.title
            e.location          = input.location
            e.detail            = input.detail
            e.startDate         = occurrenceStart
            e.endDate           = occurrenceEnd
            e.isAllDay          = NSNumber(value: input.isAllDay)
            e.isCompleted       = NSNumber(value: input.isCompleted)
            e.backgroundColor   = input.backgroundColorName
            e.repeatRule        = input.repeatRuleName
            e.hasRepeatEndDate  = input.hasRepeatEndDate
            e.repeatEndDate     = input.repeatEndDate
            e.alarm             = input.alarmRuleName
            e.scheduleType      = "manual"
            e.createdAt         = Date()
            e.updatedAt         = Date()
            e.seriesId          = seriesId
            e.occurrenceIndex   = Int64(index)
            created.append(e)
        }

        try service.saveContext()

        if input.isAlarmOn, let notifier {
            for obj in created {
                notifier.scheduleLocalNotification(for: obj)
            }
        }

        return created.map { $0.objectID }
    }

    // MARK: - Read (by UUID)
    @MainActor
    func fetch(by uuid: UUID) async throws -> ScheduleSnapshot {
        let predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        let items: [ScheduleEntity] = try service.fetch(ScheduleEntity.self, predicate: predicate, sortDescriptors: nil)
        guard let e = items.first else { throw ScheduleRepoError.notFound }

        return ScheduleSnapshot(
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

    // 공통 적용
    private func apply(_ input: ScheduleInput, to entity: ScheduleEntity, updateDates: Bool) {
        entity.title      = input.title
        entity.location   = input.location
        entity.detail     = input.detail

        if updateDates {
            entity.startDate = input.startDate
            entity.endDate   = input.endDate
        }

        entity.isAllDay        = NSNumber(value: input.isAllDay)
        entity.isCompleted     = NSNumber(value: input.isCompleted)
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

    // MARK: - Update single (by id)
    @MainActor
    func update(id uuid: UUID, with input: ScheduleInput) async throws -> NSManagedObjectID {
        let predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        let items: [ScheduleEntity] = try service.fetch(ScheduleEntity.self, predicate: predicate, sortDescriptors: nil)
        guard let obj = items.first else { throw ScheduleRepoError.notFound }

        apply(input, to: obj, updateDates: true)
        try service.saveContext()
        return obj.objectID
    }

    // MARK: - Update series (keep start/end)
    @MainActor
    func update(seriesId uuid: UUID, with input: ScheduleInput) async throws -> [NSManagedObjectID] {
        let predicate = NSPredicate(format: "seriesId == %@", uuid as CVarArg)
        let items: [ScheduleEntity] = try service.fetch(ScheduleEntity.self, predicate: predicate, sortDescriptors: nil)
        guard !items.isEmpty else { throw ScheduleRepoError.notFound }

        for obj in items {
            apply(input, to: obj, updateDates: false)
        }
        try service.saveContext()
        return items.map { $0.objectID }
    }

    // MARK: - Delete single (by uuid)
    @MainActor
    func delete(id: UUID) async throws {
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let items: [ScheduleEntity] = try service.fetch(ScheduleEntity.self, predicate: predicate, sortDescriptors: nil)
        guard let obj = items.first else { throw ScheduleRepoError.notFound }

        try service.delete(obj)
    }

    // MARK: - Delete all in series
    @MainActor
    func deleteAll(seriesId uuid: UUID) async throws -> [NSManagedObjectID] {
        let predicate = NSPredicate(format: "seriesId == %@", uuid as CVarArg)
        let items: [ScheduleEntity] = try service.fetch(ScheduleEntity.self, predicate: predicate, sortDescriptors: nil)
        guard !items.isEmpty else { throw ScheduleRepoError.notFound }

        let ids = items.map { $0.objectID }
        for obj in items {
            try service.delete(obj)
        }
        return ids
    }

    // MARK: - Delete occurrences after anchor
    @MainActor
    func deleteSeriesOccurrences(seriesId: UUID, after anchor: Date, includeAnchor: Bool) async throws {
        let op = includeAnchor ? ">=" : ">"
        let predicate = NSPredicate(format: "seriesId == %@ AND startDate \(op) %@",
                                    seriesId as CVarArg, anchor as CVarArg)
        let items: [ScheduleEntity] = try service.fetch(ScheduleEntity.self, predicate: predicate, sortDescriptors: nil)
        for obj in items {
            try service.delete(obj)
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
