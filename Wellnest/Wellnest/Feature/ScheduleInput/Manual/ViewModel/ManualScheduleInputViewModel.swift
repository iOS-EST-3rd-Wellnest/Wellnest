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

}

extension ManualScheduleInputViewModel {
    /// 저장 + (옵션) 알림 예약. 성공 시 생성된 ObjectID 반환
    @discardableResult
    func saveSchedule(_ input: ScheduleInput) async throws -> NSManagedObjectID {
        // 1) 백그라운드 컨텍스트에서 생성/저장
        let id = try await store.create(ScheduleEntity.self) { e in
            e.id           = UUID()
            e.title        = input.title
            e.location     = input.location
            e.detail       = input.detail
            e.startDate    = input.startDate
            e.endDate      = input.endDate
            e.isCompleted   = false
            e.setValue(input.isAllDay,    forKey: "isAllDay")

            e.backgroundColor   = input.backgroundColorName
            e.repeatRule        = input.repeatRuleName
            e.hasRepeatEndDate  = input.hasRepeatEndDate
            e.repeatEndDate     = input.repeatEndDate
            e.alarm             = input.alarmRuleName
            e.scheduleType      = "custom"
            e.createdAt         = Date()
            e.updatedAt         = Date()
        }

        // 2) 알림 필요 시 MainActor에서 예약
        if input.isAlarmOn {
            try await MainActor.run {
                // viewContext가 background 저장을 반영하도록:
                // App 시작 시: viewContext.automaticallyMergesChangesFromParent = true 권장
                guard let obj = try? viewContext.existingObject(with: id) as? ScheduleEntity else { return }
                notifier.scheduleLocalNotification(for: obj)
            }
        }
        return id
    }
}

extension ManualScheduleInputViewModel {
    @discardableResult
    func saveScheduleAdvanced(_ input: ScheduleInput) async throws -> NSManagedObjectID {
        try await store.performWrite { ctx in
            // 1) 유효성
            guard input.isAllDay || input.startDate < input.endDate else {
                throw EditorError.invalidTimeRange
            }

            // 2) 시리즈
            let series = EventSeriesEntity(context: ctx)
            series.id         = UUID()
            series.title      = input.title
            series.notes      = input.detail.isEmpty ? nil : input.detail
            series.location   = input.location.isEmpty ? nil : input.location
            series.isAllDay   = input.isAllDay
            series.timeZoneID = TimeZone.current.identifier
            series.anchorDate = anchorDay(of: input.startDate, tz: .current)

            series.startDate = input.startDate
            series.endDate   = input.endDate
            series.colorName = input.backgroundColorName


            // 3) 반복 규칙 생성(있을 때만)
            if let desc = makeRecurrenceDescriptor(from: input) {
                let rule = RecurrenceRuleEntity(context: ctx)
                rule.id           = UUID()
                rule.frequency = desc.freq.rawValue
                rule.interval     = desc.interval
                if let mask = desc.weekdaysMask {
                    // 속성이 Int16인지 NSNumber?인지에 맞춰 세팅
                    if let attr = rule.entity.propertiesByName["byWeekdaysMask"] as? NSAttributeDescription,
                       attr.attributeType == .integer16AttributeType {
                        rule.setValue(mask, forKey: "byWeekdaysMask")
                    } else {
                        rule.setValue(NSNumber(value: mask), forKey: "byWeekdaysMask")
                    }
                }

                rule.until = desc.until
                if !desc.excludeDates.isEmpty {
                    let blob = try JSONEncoder().encode(desc.excludeDates as [Date])
                    if let attr = rule.entity.attributesByName["excludeDatesData"],
                       attr.attributeType == .binaryDataAttributeType {
                        // excludeDatesData가 Binary Data(Data?)일 때
                        rule.excludeDatesData = blob
                    } else {
                        // Transformable(NSObject?)일 때
                        rule.excludeDatesData = blob
                    }
                }
                rule.series        = series
                series.recurrenceRule = rule
            }

            // 4) 단발성이라면 1회차 오커런스 생성
            if series.recurrenceRule == nil {
                let occ = EventOccurrenceEntity(context: ctx)
                occ.id                = UUID()
                occ.titleOverride    = input.title
                occ.locationOverride  = input.location
                occ.notesOverride    = input.detail
                occ.colorName        = input.backgroundColorName
                occ.series            = series
                occ.occurrenceDateKey = utcDateKey(for: input.startDate)
                occ.startDate         = input.startDate
                occ.endDate           = input.endDate
                occ.isCompleted       = input.isCompleted
                occ.statusRaw         = OccurrenceStatus.planned.rawValue
            }
            print(series)

            return series.objectID
        }
    }
}

enum OccurrenceStatus: Int16, CaseIterable, Codable {
    case planned  = 0
    case skipped  = 1
    case canceled = 2
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

enum EditorError: Error {
    case invalidTimeRange
}


/// 주어진 날짜의 "타임존 기준 YYYY-MM-DD"를 추출해, UTC 00:00 로 정규화한 Date를 반환.
/// - Parameters:
///   - date: 원본 시각(예: 2025-08-21 17:30 KST)
///   - tz: 해당 일자를 판단할 기준 타임존(시리즈의 timeZoneID 권장)
/// - Returns: UTC 00:00 로 정규화된 키(같은 '날짜'면 같은 값)
func utcDateKey(for date: Date, tz: TimeZone = .current) -> Date {
    // 1) 기준 타임존에서 연/월/일만 추출
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    let ymd = cal.dateComponents([.year, .month, .day], from: date)

    // 2) 같은 연/월/일을 UTC 00:00 으로 만든 절대시각 생성
    var gmtCal = Calendar(identifier: .gregorian)
    gmtCal.timeZone = TimeZone(secondsFromGMT: 0)!
    return gmtCal.date(from: ymd)!  // 항상 생성 가능
}

/// "앵커 일자"를 타임존 기준 자정으로 만든 절대시각(반복 시리즈 시작일 등에 사용)
func anchorDay(of date: Date, tz: TimeZone = .current) -> Date {
    var cal = Calendar(identifier: .gregorian); cal.timeZone = tz
    let ymd = cal.dateComponents([.year, .month, .day], from: date)
    return cal.date(from: ymd)!   // 로컬 자정(해당 타임존의 00:00)에 해당하는 절대시각
}

enum RecurrenceFreq: String {
    case none = "0", daily = "매일", weekly = "매주", monthly = "매달", yearly = "매년"
}

struct RecurrenceDescriptor {
    var freq: RecurrenceFreq
    var interval: Int16 = 1
    var weekdaysMask: Int16? = nil   // Monday=1 ... Sunday=7, bit mask
    var until: Date? = nil
    var excludeDates: [Date] = []
}

// MARK: - Public

/// ScheduleInput -> RecurrenceDescriptor (없으면 nil)
func makeRecurrenceDescriptor(from input: ScheduleInput,
                              seriesTimeZoneID: String? = nil) -> RecurrenceDescriptor? {
    if !input.isRepeat { return nil }

    guard let rule = input.repeatRuleName else { return nil }

    let tz = TimeZone(identifier: seriesTimeZoneID ?? TimeZone.current.identifier) ?? .current
    var desc = RecurrenceDescriptor(freq: .none)

    // UNTIL (종료일이 있으면 그 타임존의 하루 끝으로 보정)
    if input.hasRepeatEndDate, let end = input.repeatEndDate {
        desc.until = endOfDay(for: end, tz: tz)
    }

    switch rule {
    case "매일":
        desc.freq = .daily

    case "매주":
        desc.freq = .weekly
        desc.weekdaysMask = maskFrom(anchor: input.startDate, tz: tz) // 앵커 요일 1개

    case let s where s.hasPrefix("weekly"):
        desc.freq = .weekly
        // 예: "weekly mon,wed,fri" / "weekly 1,3,5" / "weekly 월,수,금"
        if let parsed = parseWeekdaysMask(from: s) {
            desc.weekdaysMask = parsed
        } else {
            desc.weekdaysMask = maskFrom(anchor: input.startDate, tz: tz)
        }

    case "weekdays", "weekday", "주중":
        desc.freq = .weekly
        desc.weekdaysMask = maskForWeekdays()

    case "weekends", "weekend", "주말":
        desc.freq = .weekly
        desc.weekdaysMask = maskForWeekends()

    case "매월":
        desc.freq = .monthly

    case "매년":
        desc.freq = .yearly

    default:
        // "every 2 weeks mon,wed" 같은 자유 형식까지 대략 처리
        let parsed = parseFlexible(rule: rule, anchor: input.startDate, tz: tz)
        desc.freq = parsed.freq
        desc.interval = parsed.interval
        desc.weekdaysMask = parsed.weekdaysMask
    }

    return desc
}

// Mon=1 ... Sun=7 비트 마스크
struct WeekdayMask {
    static func bit(for weekday1to7: Int) -> Int16 { 1 << Int16(weekday1to7 - 1) }
    static func from(_ weekdays: [Int]) -> Int16 { weekdays.reduce(0) { $0 | bit(for: $1) } }
    static func isoWeekday1to7(_ date: Date, tz: TimeZone) -> Int {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = tz
        let wd = cal.component(.weekday, from: date) // Sun=1 ... Sat=7
        return wd == 1 ? 7 : wd - 1                  // Mon=1 ... Sun=7 로 변환
    }
}

func maskFrom(anchor: Date, tz: TimeZone) -> Int16 {
    WeekdayMask.bit(for: WeekdayMask.isoWeekday1to7(anchor, tz: tz))
}

func maskForWeekdays() -> Int16 { WeekdayMask.from([1,2,3,4,5]) } // Mon-Fri
func maskForWeekends() -> Int16 { WeekdayMask.from([6,7]) }       // Sat-Sun

func endOfDay(for date: Date, tz: TimeZone) -> Date {
    var cal = Calendar(identifier: .gregorian); cal.timeZone = tz
    var c = cal.dateComponents([.year,.month,.day], from: date)
    c.hour = 23; c.minute = 59; c.second = 59
    return cal.date(from: c)!
}

// "weekly mon,wed,fri" / "weekly 1,3,5" / "weekly 월,수,금" 파싱
func parseWeekdaysMask(from weekly: String) -> Int16? {
    let lower = weekly.lowercased()
    guard let range = lower.range(of: "weekly") else { return nil }
    let tail = lower[range.upperBound...]
        .replacingOccurrences(of: "(", with: " ")
        .replacingOccurrences(of: ")", with: " ")
        .replacingOccurrences(of: ":", with: " ")
    let tokens = tail
        .split { ", ".contains($0) }
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    let days = tokens.compactMap { weekdayIndex($0) }
    return days.isEmpty ? nil : WeekdayMask.from(days)
}

// 유연 파서: "every 2 weeks mon,wed" 등
func parseFlexible(rule: String, anchor: Date, tz: TimeZone)
-> (freq: RecurrenceFreq, interval: Int16, weekdaysMask: Int16?) {
    var freq: RecurrenceFreq = .weekly
    var interval: Int16 = 1
    var mask: Int16? = nil

    let words = rule.split(whereSeparator: { $0 == " " || $0 == "-" || $0 == "_" })
                    .map { String($0) }

    // interval
    if let i = words.firstIndex(of: "every"), i+1 < words.count, let n = Int16(words[i+1]) {
        interval = max(1, n)
    }

    // freq
    if words.contains(where: { ["day","daily"].contains($0) })      { freq = .daily }
    if words.contains(where: { ["week","weeks","weekly"].contains($0) }) { freq = .weekly }
    if words.contains(where: { ["month","months","monthly"].contains($0) }) { freq = .monthly }
    if words.contains(where: { ["year","years","yearly","annually"].contains($0) }) { freq = .yearly }

    // weekdays
    if freq == .weekly {
        let parsed = parseWeekdaysMask(from: rule)
        mask = parsed ?? maskFrom(anchor: anchor, tz: tz)
    }

    return (freq, interval, mask)
}

// "mon/tue/.../sun", "월/화/.../일", "1..7" 지원 (Mon=1..Sun=7)
func weekdayIndex(_ token: String) -> Int? {
    let t = token.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    switch t {
    case "1","mon","m","월": return 1
    case "2","tue","t","화": return 2
    case "3","wed","w","수": return 3
    case "4","thu","th","목": return 4
    case "5","fri","f","금": return 5
    case "6","sat","s","토": return 6
    case "7","sun","su","일": return 7
    default: return nil
    }
}
