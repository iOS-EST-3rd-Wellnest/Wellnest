//
//  RepeatRule.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import Foundation

struct RepeatRule: TagModel {
    let id = UUID()
    let name: String

    static let tags: [RepeatRule] = [
        RepeatRule(name: "매일"),
        RepeatRule(name: "매주"),
        RepeatRule(name: "매월"),
        RepeatRule(name: "매년")
    ]

    init(name: String) {
        self.name = name
    }
}

enum RecurrenceFreq: Int16 { case none = 0, daily = 1, weekly = 2, monthly = 3, yearly = 4 }
enum OccurrenceStatus: Int16 { case planned = 0, skipped = 1, canceled = 2 }

extension RecurrenceRuleEntity {
    var freq: RecurrenceFreq {
        get { RecurrenceFreq(rawValue: frequencyRaw) ?? .none }
        set { frequencyRaw = newValue.rawValue }
    }

    var excludeDates: [Date] {
        get {
            guard let data = excludeDatesData else { return [] }
            // 필요하면 ISO8601 등 전략을 지정
            // let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
            return (try? JSONDecoder().decode([Date].self, from: data)) ?? []
        }
        set {
            // let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
            excludeDatesData = try? JSONEncoder().encode(newValue)
        }
    }

    var weekdaysMask: Int16 {
        get { byWeekdaysMask }
        set { byWeekdaysMask = Int16(newValue) }
    }
}


extension EventSeriesEntity {
    var timeZone: TimeZone { TimeZone(identifier: timeZoneID ?? "") ?? .current }

    // startDate / endDate → 시간 성분만 가진 DateComponents
    var startComponents: DateComponents { Self.timeOfDayComponents(from: startTimeOfDay ?? Date(), tz: timeZone) }
    var endComponents: DateComponents   { Self.timeOfDayComponents(from: endTimeOfDay ?? Date(),   tz: timeZone) }

    // all-day면 00:00로 고정하고 싶다면 이렇게
    var startComponentsForAllDayAware: DateComponents {
        isAllDay ? DateComponents(hour: 0, minute: 0, second: 0) : Self.timeOfDayComponents(from: startTimeOfDay ?? Date(), tz: timeZone)
    }

    private static func timeOfDayComponents(from date: Date, tz: TimeZone) -> DateComponents {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        // 필요에 따라 [.second], [.nanosecond] 추가
        return cal.dateComponents([.hour, .minute, .second], from: date)
    }
}

struct WeekdayMask {
    static func bit(for weekday1to7: Int) -> Int16 { 1 << Int16(weekday1to7 - 1) }

    static func contains(_ mask: Int16, weekday1to7: Int) -> Bool {
        (mask & bit(for: weekday1to7)) != 0
    }
}

