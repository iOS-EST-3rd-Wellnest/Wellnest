//
//  CalendarManager.swift
//  Wellnest
//
//  Created by 전광호 on 8/12/25.
//

import Foundation
import EventKit

@MainActor
final class CalendarManager {
    static let shared = CalendarManager()
    private let store = EKEventStore()

    /// 현재 권한 상태
    func authorizationStatus() -> EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    /// 캘린더 접근 권한 보장 (필요 시 요청)
    func ensureAccess(writeOnly: Bool = false) async throws {
        let status = authorizationStatus()

        if #available(iOS 17.0, *) {
            switch status {
            case .fullAccess: return
            case .notDetermined:
                let granted = try await (writeOnly
                    ? store.requestWriteOnlyAccessToEvents()
                    : store.requestFullAccessToEvents())
                guard granted else { throw Self.errDenied }
            default:
                throw Self.errSettings
            }
        } else {
            if status == .authorized { return }
            let granted = try await store.requestAccess(to: .event)
            guard granted else { throw Self.errDenied }
        }
    }
    
    /// 새 이벤트를 저장할 기본 캘린더
    func defaultCalendar() throws -> EKCalendar {
        if let c = store.defaultCalendarForNewEvents { return c }
        if let any = store.calendars(for: .event).first(where: { $0.allowsContentModifications }) { return any }
        throw NSError(domain: "Calendar", code: 3, userInfo: [NSLocalizedDescriptionKey: "사용 가능한 캘린더가 없습니다."])
    }

    func fetchCalendars() -> [EKCalendar] {
        store.calendars(for: .event)
    }

    func fetchEvents(startDate: Date, endDate: Date, calendars: [EKCalendar]? = nil) -> [EKEvent] {
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        return store.events(matching: predicate)
    }

    /// 이벤트 생성 또는 업데이트 후 `eventIdentifier` 반환
    /// - Parameters:
    ///   - existingId: 기존 이벤트 식별자
    ///   - title: 제목
    ///   - location: 위치(옵션)
    ///   - notes: 메모(옵션)
    ///   - startDate: 시작 시각
    ///   - endDate: 종료 시각 (all-day가 아니면 start 이후)
    ///   - isAllDay: 하루 종일 여부
    ///   - calendar: 저장할 캘린더(없으면 기본 캘린더)
    ///   - recurrenceRules: 반복 규칙(옵션)
    ///   - alarms: 알람(옵션)
    @discardableResult
    func addOrUpdateEvent(
        existingId: String?,
        title: String,
        location: String? = nil,
        notes: String? = nil,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        calendar: EKCalendar? = nil,
        recurrenceRules: [EKRecurrenceRule]? = nil,
        alarms: [EKAlarm]? = nil
    ) async throws -> String {
        try await ensureAccess() // 읽기/쓰기 권한 보장

        // 기존 이벤트가 있으면 로드, 아니면 신규
        let event: EKEvent
        if let id = existingId, let found = store.event(withIdentifier: id) {
            event = found
        } else {
            event = EKEvent(eventStore: store)
            event.calendar = try calendar ?? defaultCalendar()
        }

        // 기본 정보
        event.title = title
        event.location = location
        event.notes = notes
        event.isAllDay = isAllDay

        // 시간 설정
        if isAllDay {
            let cal = Calendar.current
            let s0 = cal.startOfDay(for: startDate)
            let e0 = cal.startOfDay(for: endDate)
            var endExclusive = cal.date(byAdding: .day, value: 1, to: e0)!
            if endExclusive <= s0 { endExclusive = cal.date(byAdding: .day, value: 1, to: s0)! } // 최소 1일
            event.startDate = s0
            event.endDate = endExclusive
        } else {
            event.startDate = startDate
            event.endDate = max(endDate, startDate.addingTimeInterval(60)) // 최소 1분 보정
        }

        // 반복/알람 (필요 시 전달)
        event.recurrenceRules = recurrenceRules
//        event.alarms = alarms

        try store.save(event, span: .futureEvents, commit: true)
        return event.eventIdentifier
    }

    /// 이벤트 삭제
    func deleteEvent(by identifier: String?) throws {
        guard let id = identifier, let ev = store.event(withIdentifier: id) else { return }
        try store.remove(ev, span: .futureEvents, commit: true)
    }

    // MARK: 편의 에러
    private static let errDenied   = NSError(domain: "Calendar", code: 1, userInfo: [NSLocalizedDescriptionKey: "캘린더 접근 권한이 거부되었습니다."])
    private static let errSettings = NSError(domain: "Calendar", code: 2, userInfo: [NSLocalizedDescriptionKey: "설정 앱에서 캘린더 접근을 허용해주세요."])
}
