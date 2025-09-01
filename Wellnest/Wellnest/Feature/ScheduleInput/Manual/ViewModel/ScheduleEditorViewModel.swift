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

    func loadIfNeeded() async {
        guard case let .edit(id) = mode else { return }
        do {
            let scheduleSnapshot = try await repository.fetch(by: id)
            await MainActor.run {
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
            }

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

        var input = ScheduleInput(
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
                let fetch = try await repository.fetch(by: id)
                input.isCompleted = fetch.isCompleted
                let updated = try await repository.update(id: id, with: input)
                lastSavedID = updated
            }
            return updated
        }
    }

    @MainActor
    func updateRepeatRule() async throws {
        guard case let .edit(id) = mode else { return }
        let fetch = try await repository.fetch(by: id)

        let keepCompleted = fetch.isCompleted

        try await repository.deleteSeriesOccurrences(
            seriesId: fetch.seriesId ?? UUID(),
            after: fetch.startDate,
            includeAnchor: false
        )

        var inputForSelected = ScheduleInput(
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
            isCompleted: keepCompleted       // ✅ 선택된 것만 완료 유지
        )
        try await repository.update(id: id, with: inputForSelected)

        // 4) 이후 발생분은 항상 미완료로 생성
        //    - 생성 API가 "하나씩" 만드는 경우: 익스팬더로 9/1..9/7 구해 루프에서 create
        //    - 생성 API가 "규칙 전체"를 만드는 경우: 앵커의 다음 발생일부터 만들도록 설정
        var inputForFuture = inputForSelected
        inputForFuture.isCompleted = false   // ✅ 새 occurrence는 항상 미완료

        // 앵커의 다음 발생부터 시작하도록 시작/끝을 조정 (예: daily라면 +1일)
        // 규칙에 따라 nextStart를 계산하세요. (아래는 daily 예시)
        let duration = inputForSelected.endDate.timeIntervalSince(inputForSelected.startDate)
        let nextStart = Calendar.current.date(byAdding: .day, value: 1, to: fetch.startDate) ?? fetch.startDate
        inputForFuture.startDate = nextStart
        inputForFuture.endDate   = nextStart.addingTimeInterval(duration)

        // 반복 종료일(있다면) 그대로 유지 → nextStart > repeatEndDate면 create 내부에서 no-op 처리
        try await repository.create(with: inputForFuture)
    }

    @MainActor
    func updateRepeatSeries() async throws {
        guard case let .edit(selectedID) = mode else { return }

        let selected = try await repository.fetch(by: selectedID)
        guard let seriesId = selected.seriesId else { return }

        let timeDelta = form.startDate.timeIntervalSince(selected.startDate)

        let baseInput = ScheduleInput(
            title: form.title,
            location: form.location,
            detail: form.detail,
            startDate: selected.startDate,
            endDate: selected.endDate,
            isAllDay: form.isAllDay,
            backgroundColorName: form.selectedColorName,
            repeatRuleName: form.isRepeated ? form.selectedRepeatRule?.name : nil,
            hasRepeatEndDate: form.hasRepeatEndDate,
            repeatEndDate: form.hasRepeatEndDate ? form.repeatEndDate : nil,
            alarmRuleName: form.isAlarmOn ? form.alarmRule?.name : nil,
            isAlarmOn: form.isAlarmOn,
            isCompleted: false
        )

        let ctx = CoreDataService.shared.context
        let fetchReq = NSFetchRequest<NSManagedObjectID>(entityName: "ScheduleEntity")
        fetchReq.resultType = .managedObjectIDResultType
        fetchReq.predicate = NSPredicate(format: "seriesId == %@", seriesId as CVarArg)

        let allIDs = try ctx.fetch(fetchReq)

        try await ctx.perform {
            for oid in allIDs {
                guard let obj = try? ctx.existingObject(with: oid) as? ScheduleEntity else { continue }

                obj.title = baseInput.title
                obj.detail = baseInput.detail
                obj.location = baseInput.location
                obj.backgroundColor = baseInput.backgroundColorName
                obj.isAllDay = NSNumber(value: baseInput.isAllDay)
                obj.alarm = baseInput.alarmRuleName
                obj.repeatRule = baseInput.repeatRuleName
                obj.hasRepeatEndDate = baseInput.hasRepeatEndDate
                obj.repeatEndDate = baseInput.repeatEndDate


                if timeDelta != 0 {
                    if let s = obj.startDate { obj.startDate = s.addingTimeInterval(timeDelta) }
                    if let e = obj.endDate   { obj.endDate   = e.addingTimeInterval(timeDelta) }
                } else {
                    // 시간 이동을 원치 않으면 아무 것도 하지 않음
                    // (혹은 선택 아이템의 duration로 재계산하고 싶다면 여기서 처리)
                }
            }
        }

        try CoreDataService.shared.saveContext()
        ctx.processPendingChanges()
    }
    @MainActor
    func editFollowingAndReseries() async throws {
        guard case let .edit(id) = mode else { return }
        let ctx = CoreDataService.shared.context

        // 선택된 아이템과 seriesId 확보
        let selected = try await repository.fetch(by: id)
        guard let seriesId = selected.seriesId else { return }

        // (옵션) 시간 이동량을 쓰고 싶다면 사용
        let timeDelta = form.startDate.timeIntervalSince(selected.startDate)

        // 같은 seriesId 전부 조회
        let req = NSFetchRequest<ScheduleEntity>(entityName: "ScheduleEntity")
        req.predicate = NSPredicate(format: "seriesId == %@", seriesId as CVarArg)
        let items = try ctx.fetch(req)

        print("seriesId items: \(items)")

        try await ctx.perform { [weak self] in
            guard let self else { return }

            for obj in items {
                // ✅ 콘텐츠 속성만 업데이트 (제목/메모/장소/색/종일/알람)
                obj.title = self.form.title
                obj.detail = self.form.detail
                obj.location = self.form.location
                obj.backgroundColor = self.form.selectedColorName
                obj.isAllDay = NSNumber(value: self.form.isAllDay)
                obj.alarm = self.form.isAlarmOn ? self.form.alarmRule?.name : nil

                // ❌ 반복/식별/완료 상태는 유지
                // obj.repeatRule / obj.hasRepeatEndDate / obj.repeatEndDate / obj.seriesId / obj.isCompleted 그대로

                // (선택) 전체 시간을 동일 Δ만큼 이동하고 싶다면 주석 해제
                // if timeDelta != 0 {
                //     if let s = obj.startDate { obj.startDate = s.addingTimeInterval(timeDelta) }
                //     if let e = obj.endDate   { obj.endDate   = e.addingTimeInterval(timeDelta) }
                // }
            }
        }

        try CoreDataService.shared.saveContext()
        ctx.processPendingChanges()
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
