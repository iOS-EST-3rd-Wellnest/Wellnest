//
//  ManualScheduleInputViewModel.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/16/25.
//

import CoreData

final class ManualScheduleInputViewModel {
    private let store: CoreDataStore            // actor (백그라운드 CRUD)
    private let viewContext: NSManagedObjectContext
    private let notifier: LocalNotifying

    init(store: CoreDataStore,
         viewContext: NSManagedObjectContext,
         notifier: LocalNotifying) {
        self.store = store
        self.viewContext = viewContext
        self.notifier = notifier
    }

    /// 저장 + (옵션) 알림 예약. 성공 시 생성된 ObjectID 반환
    @discardableResult
    func saveSchedule(_ input: ScheduleInput) async throws -> NSManagedObjectID {
        // 1) 백그라운드 컨텍스트에서 생성
        let id = try await store.create(ScheduleEntity.self) { e in
            e.id = UUID()
            e.eventIdentifier = input.eventIdentifier
            e.title = input.title
            e.location = input.location
            e.detail = input.detail
            e.startDate = input.startDate
            e.endDate = input.endDate
            e.isAllDay = input.isAllDay as NSNumber
            e.isCompleted = input.isCompleted as NSNumber
            e.backgroundColor = input.backgroundColorName
            e.repeatRule = input.repeatRuleName
            e.hasRepeatEndDate = input.hasRepeatEndDate
            e.repeatEndDate = input.repeatEndDate
            e.alarm = input.alarmRuleName
            e.scheduleType = "custom"
            e.createdAt = Date()
            e.updatedAt = Date()
            print(e)
        }

        // 2) 알림 필요 시 MainActor에서 바인딩 후 예약
        if input.isAlarmOn {
            try await MainActor.run {
                guard let obj = try viewContext.existingObject(with: id) as? ScheduleEntity else { return }
                notifier.scheduleLocalNotification(for: obj)
            }
        }
        return id
    }
    
    /// CoreData에 저장된 일정에 Event Kit의 Identifier를 붙임
    /// Event Kit 일정과 CoreData일정이 서로 연결
    @MainActor
    func attachEventIdentifier(_ ekId: String, to objectID: NSManagedObjectID) async throws {
        guard let obj = try? viewContext.existingObject(with: objectID) as? ScheduleEntity else { return }
        obj.eventIdentifier = ekId
        obj.updatedAt = Date()
        try viewContext.save()
    }
}

enum ScheduleEditorFactory {
    static func makeDefault() -> ManualScheduleInputViewModel {
        let container = CoreDataStack.shared.container
        let viewContext = container.viewContext
        let store = CoreDataStore(container: container) // actor
        let notifier: LocalNotifying = LocalNotiManager.shared
        return ManualScheduleInputViewModel(store: store,
                              viewContext: viewContext,
                              notifier: notifier)
    }
}
