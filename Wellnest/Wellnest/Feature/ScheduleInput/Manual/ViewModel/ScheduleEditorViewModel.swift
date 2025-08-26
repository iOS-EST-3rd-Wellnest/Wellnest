//
//  ScheduleEditorViewModel.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/25/25.
//

import CoreData
import SwiftUI

enum EditorMode: Equatable {
    case create
    case edit(id: UUID)
}

final class ScheduleEditorViewModel: ObservableObject {
    @Published var form = ScheduleFormState()
    @Published var previewColor: Color = .wellnestBlue
    @Published var lastSavedID: NSManagedObjectID?
    @Published var isSaving = false

    private let mode: EditorMode
    private let repository: ScheduleRepository

    init(mode: EditorMode, repository: ScheduleRepository) {
        self.mode = mode
        self.repository = repository

        if case .create = mode {
            form.startDate = Date().roundedUpToFiveMinutes()
            form.endDate   = Date().addingTimeInterval(3600).roundedUpToFiveMinutes()
        }
    }

    var navigationBarTitle: String {
        switch mode {
        case .create:
            return "새 일정"
        case .edit:
            return "일정 수정"
        }
    }

    var primaryButtonTitle: String {
        switch mode {
        case .create:
            return "저장하기"
        case .edit:
            return "수정하기"
        }
    }

    var canDelete: Bool {
        switch mode {
        case .create:
            return false
        case .edit:
            return true
        }
    }

    func updateColorName(_ name: String) {
        form.selectedColorName = name
        previewColor = Color(name)
    }

    @MainActor
    func loadIfNeeded() async {
        guard case let .edit(id) = mode else { return }
        do {
            let scheduleSnapshot = try await repository.fetch(by: id)
            form = ScheduleFormState(
                title: scheduleSnapshot.title,
                location: scheduleSnapshot.location,
                detail: scheduleSnapshot.detail,
                startDate: scheduleSnapshot.startDate,
                endDate: scheduleSnapshot.endDate,
                isAllDay: scheduleSnapshot.isAllDay,
                isRepeated: scheduleSnapshot.repeatRuleName != nil,
                selectedRepeatRule: scheduleSnapshot.repeatRuleName.flatMap(RepeatRule.init(name:)),
                repeatEndMode: (scheduleSnapshot.repeatEndDate == nil) ? .none : .date,
                repeatEndDate: scheduleSnapshot.repeatEndDate ?? Date(),
                isAlarmOn: scheduleSnapshot.isAlarmOn,
                alarmRule: scheduleSnapshot.alarmRuleName.flatMap(AlarmRule.init(name:)),
                selectedColorName: scheduleSnapshot.backgroundColorName
            )
            previewColor = Color(form.selectedColorName)
        } catch {
            print("편집 데이터 로드 실패: \(error)")
        }
    }

    @discardableResult
    @MainActor
    func saveSchedule() async throws -> [NSManagedObjectID] {
        isSaving = true
        defer { isSaving = false }

        let input = ScheduleInput(
            title: form.title,
            location: form.location,
            detail: form.detail,
            startDate: form.startDate,
            endDate: form.endDate,
            isAllDay: form.isAllDay,
            backgroundColorName: form.selectedColorName,
            repeatRuleName: form.isRepeated ? form.selectedRepeatRule?.name : nil,
            hasRepeatEndDate: form.hasRepeatEndDate,
            repeatEndDate: form.hasRepeatEndDate ? form.repeatEndDate : nil,
            alarmRuleName: form.isAlarmOn ? form.alarmRule?.name : nil,
            isAlarmOn: form.isAlarmOn,
            isCompleted: false
        )

        switch mode {
        case .create:
            let ids = try await repository.create(with: input)
            lastSavedID = ids.first
            return ids
        case let .edit(id):
            let updated = try await repository.update(id: id, with: input)
            lastSavedID = updated
            return [updated]
        }
    }
}

enum ScheduleEditorFactory {
    static func make(mode: EditorMode) -> ScheduleEditorViewModel {
        let container = CoreDataStack.shared.container
        let viewContext = container.viewContext
        let store = CoreDataStore(container: container)
        let notifier: LocalNotifying = LocalNotiManager.shared
        let repository = CoreDataScheduleRepository(store: store, viewContext: viewContext, notifier: notifier)
        return ScheduleEditorViewModel(mode: mode, repository: repository)
    }
}
