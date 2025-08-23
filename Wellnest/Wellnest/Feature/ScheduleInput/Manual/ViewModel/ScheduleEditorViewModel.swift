//
//  ManualScheduleInputViewModel.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/16/25.
//

import CoreData
import SwiftUI

final class ScheduleEditorViewModel: ObservableObject {
    @Published var form = ScheduleFormState()
    @Published var previewColor: Color = .milkyBlue
    @Published var lastSavedID: NSManagedObjectID?
    @Published var isSaving = false
    @Published var isLoading = false

    let mode: EditorMode
    private let repo: ScheduleRepository

    init(mode: EditorMode, repo: ScheduleRepository) {
        self.mode = mode
        self.repo = repo

        // 생성 기본값(5분 올림)은 VM 책임
        if case .create = mode {
            form.startDate = Date().roundedUpToFiveMinutes()
            form.endDate   = Date().addingTimeInterval(3600).roundedUpToFiveMinutes()
        }
    }

    var navTitle: String { mode == .create ? "새 일정" : "일정 수정" }
    var primaryButtonTitle: String { mode == .create ? "저장하기" : "업데이트" }
    var canDelete: Bool { if case .edit = mode { return true } else { return false } }


    func updateColorName(_ name: String) {
        form.selectedColorName = name
        previewColor = Color(name)
    }

    @MainActor
    func loadIfNeeded() async {
        guard case let .edit(id) = mode else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let s = try await repo.fetch(by: id)
            form = ScheduleFormState(
                title: s.title,
                location: s.location,
                detail: s.detail,
                startDate: s.startDate,
                endDate: s.endDate,
                isAllDay: s.isAllDay,
                isRepeated: s.repeatRuleName != nil,
                selectedRepeatRule: s.repeatRuleName.flatMap(RepeatRule.init(name:)),
                hasRepeatEndDate: s.repeatEndDate != nil,
                repeatEndDate: s.repeatEndDate ?? Date(),
                isAlarmOn: s.isAlarmOn,
                alarmRule: s.alarmRuleName.flatMap(AlarmRule.init(name:)),
                selectedColorName: s.backgroundColorName
            )
            previewColor = Color(form.selectedColorName)
        } catch {
            print("편집 데이터 로드 실패: \(error)")
        }
    }

    /// 생성은 다건 반환(반복 전개), 수정은 단건 반환을 배열화
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
            repeatEndDate: form.isRepeated ? form.repeatEndDate : nil,
            alarmRuleName: form.isAlarmOn ? form.alarmRule?.name : nil,
            isAlarmOn: form.isAlarmOn,
            isCompleted: false
        )

        switch mode {
        case .create:
            let ids = try await repo.create(with: input)
            lastSavedID = ids.first
            return ids
        case let .edit(id):
            let updated = try await repo.update(id: id, with: input)
            lastSavedID = updated
            return [updated]
        }
    }

    @MainActor
    func deleteSchedule() async throws {
        guard case let .edit(id) = mode else { return }
        try await repo.delete(id: id)
    }
}

enum ScheduleEditorFactory {
    static func make(mode: EditorMode) -> ScheduleEditorViewModel {
        let container = CoreDataStack.shared.container
        let viewContext = container.viewContext
        let store = CoreDataStore(container: container)
        let notifier: LocalNotifying = LocalNotiManager.shared
        let repo = CoreDataScheduleRepository(store: store, viewContext: viewContext, notifier: notifier)
        return ScheduleEditorViewModel(mode: mode, repo: repo)
    }
}
