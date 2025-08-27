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

    var canUpdateAll: Bool {
        switch mode {
        case .create:
            return false
        case .edit:
            if form.isRepeated {
                return true
            }
            return false
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

    var isEditMode: Bool {
        switch mode {
        case .create: return false
        case .edit: return true
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
                selectedRepeatRule: scheduleSnapshot.repeatRuleName.flatMap { RepeatRule.init(name: $0) },
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

    func setDefaultDate(for selectedDate: Date = Date()) {
        form.startDate = selectedDate.roundedUpToFiveMinutes()
        form.endDate   = form.startDate.addingTimeInterval(3600).roundedUpToFiveMinutes()
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
            isCompleted: false,
        )
        print(input)

        switch mode {
        case .create:
            let ids = try await repository.create(with: input)
            lastSavedID = ids.first
            return ids
        case let .edit(id):
            var updated: [NSManagedObjectID] = []
            if form.isRepeated {
                let delete = try await repository.delete(id: id)
                let ids = try await repository.create(with: input)

            } else {
                let updated = try await repository.update(id: id, with: input)
                lastSavedID = updated
            }
            return updated
        }
    }

    @MainActor
    func updateAll() async throws  {
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
            isCompleted: false,
        )

        switch mode {
        case let .edit(id):
            let entity = try await repository.fetch(by: id)
            let updated = try await repository.update(seriesId: entity.seriesId ?? UUID(), with: input)
        default: break
        }

    }

    @MainActor
    func delete() async throws {
        if case let .edit(id) = mode {
            try await repository.delete(id: id)
        }
    }

    @MainActor
    func deleteAll() async throws {
        if case let .edit(id) = mode {
            let snapshot = try await repository.fetch(by: id)
            try await repository.deleteAll(seriesId: snapshot.seriesId ?? UUID())
        }
    }

    @MainActor
    func deleteFollowingInSeries() async throws {
        guard case let .edit(objectID) = mode else { return }

        let snapshot = try await repository.fetch(by: objectID)
        guard let seriesId = snapshot.seriesId else { return }
        let anchor = snapshot.startDate

        // 기준 아이템보다 "늦은 것만" 삭제 ⇒ startDate > anchor
        try await repository.deleteSeriesOccurrences(
            seriesId: seriesId,
            after: anchor,
            includeAnchor: true
        )
    }
}

enum ScheduleEditorFactory {
    static func make(mode: EditorMode) -> ScheduleEditorViewModel {
        let service = CoreDataService.shared
        let notifier: LocalNotifying = LocalNotiManager.shared
        let repository = CoreDataScheduleRepository(service: service, notifier: notifier)
        return ScheduleEditorViewModel(mode: mode, repository: repository)
    }
}
