//
//  CoreDataScheduleRepository.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/23/25.
//

import Foundation
import CoreData

protocol ScheduleRepository {
    // 생성(반복 규칙이 있으면 내부에서 전개하여 다건 생성)
    func create(with input: ScheduleInput) async throws -> [NSManagedObjectID]

    // 단건 조회/수정/삭제 (수정은 관례상 단건)
    func fetch(by id: NSManagedObjectID) async throws -> ScheduleSnapshot
    func update(id: NSManagedObjectID, with input: ScheduleInput) async throws -> NSManagedObjectID
    func delete(id: NSManagedObjectID) async throws
}

final class CoreDataScheduleRepository: ScheduleRepository {
    private let store: CoreDataStore
    private let viewContext: NSManagedObjectContext
    private let notifier: LocalNotifying?

    init(store: CoreDataStore, viewContext: NSManagedObjectContext, notifier: LocalNotifying? = nil) {
        self.store = store
        self.viewContext = viewContext
        self.notifier = notifier
    }

    // MARK: - Create (반복 전개 포함)
    func create(with input: ScheduleInput) async throws -> [NSManagedObjectID] {
        let frequency = RepeatRuleParser.frequency(from: input.repeatRuleName)
        let duration = input.endDate.timeIntervalSince(input.startDate)

        let occurrences: [Date] = {
            guard let frequency else { return [input.startDate] }
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
                e.isAllDay = NSNumber(value: input.isAllDay)     // ✅ NSNumber 변환
                e.isCompleted = NSNumber(value: input.isCompleted)
                e.backgroundColor = input.backgroundColorName    // 현재 엔티티 필드명에 맞춤
                e.repeatRule = input.repeatRuleName
                e.hasRepeatEndDate = input.hasRepeatEndDate
                e.repeatEndDate = input.repeatEndDate
                e.alarm = input.alarmRuleName
                e.scheduleType = "manual"
                e.createdAt = Date()
                e.updatedAt = Date()
                e.seriesId = seriesId
                e.occurrenceIndex = Int64(idx)
            }
            createdIDs.append(id)
        }

        // 알림 스케줄링(옵션 DI)
        if input.isAlarmOn, let notifier {
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

    // MARK: - Read
    func fetch(by id: NSManagedObjectID) async throws -> ScheduleSnapshot {
        try await viewContext.perform {
            guard let e = try? self.viewContext.existingObject(with: id) as? ScheduleEntity else {
                throw ScheduleRepoError.notFound
            }
            return ScheduleSnapshot(
                id: e.objectID,
                title: e.title ?? "",
                location: e.location ?? "",
                detail: e.detail ?? "",
                startDate: e.startDate ?? Date(),
                endDate: e.endDate ?? Date(),
                isAllDay: e.isAllDay?.boolValue ?? false,
                backgroundColorName: e.backgroundColor ?? "accentButtonColor",
                repeatRuleName: e.repeatRule,
                repeatEndDate: e.repeatEndDate,
                alarmRuleName: e.alarm,
                isAlarmOn: e.alarm != nil, // 필요 시 별도 Bool 필드로 교체
                isCompleted: e.isCompleted?.boolValue ?? false
            )
        }
    }

    // MARK: - Update (단건 업데이트 예시)
    func update(id: NSManagedObjectID, with input: ScheduleInput) async throws -> NSManagedObjectID {
        try await viewContext.perform {
            guard let e = try? self.viewContext.existingObject(with: id) as? ScheduleEntity else {
                throw ScheduleRepoError.notFound
            }
            e.title = input.title
            e.location = input.location
            e.detail = input.detail
            e.startDate = input.startDate
            e.endDate = input.endDate
            e.isAllDay = NSNumber(value: input.isAllDay)
            e.isCompleted = NSNumber(value: input.isCompleted)
            e.backgroundColor = input.backgroundColorName
            e.repeatRule = input.repeatRuleName
            e.hasRepeatEndDate = input.hasRepeatEndDate
            e.repeatEndDate = input.repeatEndDate
            e.alarm = input.alarmRuleName
            e.updatedAt = Date()
            try self.viewContext.save()
            return e.objectID
        }
    }

    // MARK: - Delete
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


/// 화면/도메인에서 쓰기 쉬운 스냅샷(plain struct)
struct ScheduleSnapshot {
    let id: NSManagedObjectID
    let title: String
    let location: String
    let detail: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let backgroundColorName: String
    let repeatRuleName: String?      // nil = 반복 없음
    let repeatEndDate: Date?
    let alarmRuleName: String?
    let isAlarmOn: Bool
    let isCompleted: Bool
}

enum ScheduleRepoError: Error {
    case notFound
    case invalid(String)
    case underlying(Error)
}
