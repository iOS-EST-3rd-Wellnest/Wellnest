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

@MainActor
final class ScheduleEditorViewModel: ObservableObject {
    @Published var form = ScheduleFormState()
    @Published var previewColor: Color = .wellnestAccentPeach
    @Published var lastSavedID: NSManagedObjectID?
    @Published var isSaving = false

    private let mode: EditorMode
    private let repository: ScheduleRepository

    init(mode: EditorMode, repository: ScheduleRepository) {
        self.mode = mode
        self.repository = repository


        form.startDate = form.startDate.roundedUpToFiveMinutes()
        form.endDate = form.endDate.roundedUpToFiveMinutes()
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
        guard case let .edit(id) = mode else { return false }
        return true
    }

    func combine(date: Date, time: Date = Date()) -> Date? {
        let calendar = Calendar.current

        // 날짜에서 연월일 추출
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        // 시간에서 시분초 추출
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)

        // 합쳐서 새로운 DateComponents 생성
        var mergedComponents = DateComponents()
        mergedComponents.year = dateComponents.year
        mergedComponents.month = dateComponents.month
        mergedComponents.day = dateComponents.day
        mergedComponents.hour = timeComponents.hour
        mergedComponents.minute = timeComponents.minute
        mergedComponents.second = timeComponents.second

        return calendar.date(from: mergedComponents)
    }

    func updateColorName(_ name: String) {
        if isValidColorAsset(named: name) {
            form.selectedColorName = name
            previewColor = Color(name)
        } else {
            form.selectedColorName = "wellnestAccentPeach"
            previewColor = Color("wellnestAccentPeach")
        }
    }

    func isValidColorAsset(named name: String) -> Bool {
        return UIColor(named: name) != nil
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

    func updateRepeatRule() async throws {
        try await deleteFollowingInSeries()
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
        try await repository.create(with: input)
    }

    func updateRepeatSeries() async throws {
        guard case let .edit(id) = mode else { return }
        let current = try await repository.fetch(by: id)
        guard let seriesId = current.seriesId else { return }

        let anchor = current.startDate
        try await repository.deleteSeriesOccurrences(
            seriesId: seriesId,
            after: anchor,
            includeAnchor: true
        )

        // (선택) 인덱스 이어붙이기: 앵커 이전 개수 계산
//        let startIndex = try repository.countOccurrencesBefore(seriesId: seriesId, anchor: anchor)

        try CoreDataService.shared.saveContext()
        CoreDataService.shared.context.processPendingChanges()
        await Task.yield() // 한 틱 양보로 경합 제거

        // 3) 새 전개 입력은 seed-first(앵커부터)
        let duration = form.endDate.timeIntervalSince(form.startDate)
        var input = ScheduleInput(
            title: form.title,
            location: form.location,
            detail: form.detail,
            startDate: anchor,
            endDate: anchor.addingTimeInterval(duration),
            isAllDay: form.isAllDay,
            backgroundColorName: form.selectedColorName,
            repeatRuleName: form.isRepeated ? form.selectedRepeatRule?.name : nil,
            hasRepeatEndDate: form.hasRepeatEndDate,
            repeatEndDate: form.hasRepeatEndDate ? form.repeatEndDate : nil,
            alarmRuleName: form.isAlarmOn ? form.alarmRule?.name : nil,
            isAlarmOn: form.isAlarmOn,
            isCompleted: false
        )

        _ = try await repository.create(with: input)
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

        try await repository.deleteSeriesOccurrences(
            seriesId: seriesId,
            after: anchor,
            includeAnchor: true
        )
    }
}

enum ScheduleEditorFactory {
    @MainActor
    static func make(mode: EditorMode) -> ScheduleEditorViewModel {
        let service = CoreDataService.shared
        let notifier: LocalNotifying = LocalNotiManager.shared
        let repository = CoreDataScheduleRepository(service: service, notifier: notifier)
        return ScheduleEditorViewModel(mode: mode, repository: repository)
    }
}



enum Frequency {
    case daily(Int), weekly(Int), monthly(Int) // interval 포함
    var component: Calendar.Component {
        switch self {
        case .daily:   return .day
        case .weekly:  return .weekOfYear
        case .monthly: return .month
        }
    }
    var interval: Int {
        switch self {
        case .daily(let n), .weekly(let n), .monthly(let n): return n
        }
    }
}

struct RepeatRuleParser2 {
    static func frequency(from ruleName: String?) -> Frequency? {
        // 예: "weekly" -> .weekly(1), "biweekly" -> .weekly(2) 등
        // 프로젝트 규칙에 맞춰 매핑
        return .weekly(1) // 예시
    }

    /// ✅ seed-first: 앵커(start)를 **먼저 append**하고, 그 다음 주기로 전진
    static func generateOccurrences(start: Date, end: Date?, frequency: Frequency) -> [Date] {
        var out: [Date] = []
        var current = start
        let cal = Calendar.current
        while end == nil || current <= end! {
            out.append(current)
            guard let next = cal.date(byAdding: frequency.component,
                                      value: frequency.interval,
                                      to: current) else { break }
            current = next
        }
        return out
    }
}
