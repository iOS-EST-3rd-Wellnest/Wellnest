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
    
    /// iOS 캘린더에 등록된 일정들을 가져옴
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
        try await ensureAccess()
        
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
        
        try store.save(event, span: .thisEvent, commit: true)
        return event.eventIdentifier
    }
    
    // MARK: 캘린더 연동 삭제 -
    enum DeleteSpan {
        case thisOnly
        case futureEvent
        
        var ekSpan: EKSpan {
            self == .thisOnly ? .thisEvent : .futureEvents
        }
    }
    
    /// 이벤트 삭제
    func deleteEvent(by identifier: String?, span: DeleteSpan = .thisOnly, commit: Bool = true) throws {
        guard let id = identifier else {
            print("⚠️ deleteEvent: identifier is nil")
            return
        }
        
        guard let ev = store.event(withIdentifier: id) else {
            print("⚠️ deleteEvent: event not found for id=\(id). Need full access or id changed.")
            return
        }
        
        try store.remove(ev, span: span.ekSpan, commit: commit)
    }
    
    func backfillEventIdentifier(
        title: String?,
        location: String?,
        isAllDay: Bool?,
        startDate: Date,
        endDate: Date?,
        in calendars: [EKCalendar]? = nil
    ) async throws -> String? {
        try await ensureAccess() // full access (읽기 필요)
        
        let windowStart = startDate.addingTimeInterval(-6 * 60 * 60) // -6h
        let windowEnd   = (endDate ?? startDate.addingTimeInterval(60*60)).addingTimeInterval(6 * 60 * 60)
        
        let pred = store.predicateForEvents(withStart: windowStart, end: windowEnd, calendars: calendars)
        let cands = store.events(matching: pred)
        
        let target = cands
            .filter { ev in
                let tOK  = (title?.isEmpty ?? true) ? true : (ev.title == title)
                let aOK  = isAllDay.map { ev.isAllDay == $0 } ?? true
                let lOK: Bool = {
                    guard let loc = location, !loc.isEmpty else { return true }
                    return (ev.location ?? "") == loc
                }()
                return tOK && aOK && lOK
            }
            .min(by: { a, b in
                func dist(_ ev: EKEvent) -> TimeInterval {
                    let s = abs(ev.startDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)
                    let e = abs(ev.endDate.timeIntervalSince1970 - (endDate ?? startDate.addingTimeInterval(60*60)).timeIntervalSince1970)
                    return s + e
                }
                return dist(a) < dist(b)
            })
        
        return target?.eventIdentifier
    }
    
    @discardableResult
    func deleteEventOrBackfill(
        identifier: String?,
        title: String?,
        location: String?,
        isAllDay: Bool?,
        startDate: Date?,
        endDate: Date?,
        in calendars: [EKCalendar]? = nil
    ) async -> Bool {
        do {
            try await ensureAccess()
            
            if let id = identifier, !id.isEmpty {
                do {
                    try deleteEvent(by: id)
                    print("✅ Calendar deleted by id:", id)
                    return true
                } catch {
                    // 계속 진행해서 폴백으로도 지워본다
                    print("ℹ️ delete by id failed, try fallback:", error)
                }
            }
            
            // 시작 시간이 없으면 폴백 불가
            guard let s = startDate else {
                print("⚠️ delete fallback needs startDate")
                return false
            }
            let e = endDate ?? s.addingTimeInterval(60 * 60)
            
            // 탐색 윈도우(앞뒤 6시간)
            let windowStart = s.addingTimeInterval(-6 * 60 * 60)
            let windowEnd   = e.addingTimeInterval( 6 * 60 * 60)
            
            // 후보 검색
            let pred = store.predicateForEvents(withStart: windowStart, end: windowEnd, calendars: calendars)
            let candidates = store.events(matching: pred)
            
            // 매칭 필터
            let filtered = candidates.filter { ev in
                let titleOK: Bool = {
                    if let t = title?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
                        return ev.title == t
                    }
                    return true
                }()
                let locationOK: Bool = {
                    if let loc = location?.trimmingCharacters(in: .whitespacesAndNewlines), !loc.isEmpty {
                        return (ev.location ?? "") == loc
                    }
                    return true
                }()
                let allDayOK: Bool = {
                    if let ad = isAllDay { return ev.isAllDay == ad }
                    return true
                }()
                return titleOK && locationOK && allDayOK
            }
            
            // 시간 근접도로 최적 후보
            func timeDistance(_ ev: EKEvent) -> TimeInterval {
                abs(ev.startDate.timeIntervalSince1970 - s.timeIntervalSince1970)
                + abs(ev.endDate.timeIntervalSince1970   - e.timeIntervalSince1970)
            }
            let target = filtered.min(by: { timeDistance($0) < timeDistance($1) })
            ?? candidates.min(by: { timeDistance($0) < timeDistance($1) })
            
            guard let victim = target else {
                print("⚠️ no calendar event found for fallback delete")
                return false
            }
            
            try deleteEvent(by: victim.eventIdentifier)
            print("✅ Calendar deleted via fallback (id: \(String(describing: victim.eventIdentifier)))")
            return true
        } catch {
            print("❌ deleteEventOrBackfill failed:", error)
            return false
        }
    }
    
    // MARK: AI일정 생성 -
    
    func weeklyRecurrence(weekdays: [Int], end: Date?) -> EKRecurrenceRule {
            let days = weekdays.compactMap { EKWeekday(rawValue: $0) }.map { EKRecurrenceDayOfWeek($0) }
            let endRule = end.map { EKRecurrenceEnd(end: $0) }
            return EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 1,
                daysOfTheWeek: days,
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: endRule
            )
        }
    
    // MARK: 편의 에러 -
    private static let errDenied   = NSError(domain: "Calendar", code: 1, userInfo: [NSLocalizedDescriptionKey: "캘린더 접근 권한이 거부되었습니다."])
    private static let errSettings = NSError(domain: "Calendar", code: 2, userInfo: [NSLocalizedDescriptionKey: "설정 앱에서 캘린더 접근을 허용해주세요."])
}
