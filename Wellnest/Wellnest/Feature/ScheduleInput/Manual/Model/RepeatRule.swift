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

extension RepeatRule {
    func nextDate(from date: Date) -> Date? {
        let calendar = Calendar.current

        switch self.name {
        case "매일":
            return calendar.date(byAdding: .day, value: 1, to: date)
        case "매주":
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case "매월":
            return calendar.date(byAdding: .month, value: 1, to: date)
        case "매년":
            return calendar.date(byAdding: .year, value: 1, to: date)
        default:
            return nil
        }
    }

    func generateDates(from startDate: Date, until endDate: Date?) -> [Date] {
        var dates: [Date] = [startDate]
        var currentDate = startDate

        let maxOccurrences = 1000
        var count = 0

        while count < maxOccurrences {
            guard let nextDate = self.nextDate(from: currentDate) else { break }

            if let endDate = endDate, nextDate > endDate {
                break
            }

            dates.append(nextDate)
            currentDate = nextDate
            count += 1
        }

        return dates
    }

    static func from(string: String?) -> RepeatRule? {
        guard let string = string else { return nil }
        return RepeatRule.tags.first { $0.name == string }
    }
}
