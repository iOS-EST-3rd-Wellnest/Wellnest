//
//  RepeatRuleParser.swift
//  Wellnest
//
//  Created by 박동언 on 8/22/25.
//

import Foundation

enum RepeatFrequency {
    case daily, weekly, monthly, yearly
}

enum RepeatRuleParser {
    static func frequency(from name: String?) -> RepeatFrequency? {
        switch name {
        case "매일": return .daily
        case "매주": return .weekly
        case "매월": return .monthly
        case "매년": return .yearly
        default: return nil
        }
    }

    static func generateOccurrences(
        start: Date,
        end: Date?,
        frequency: RepeatFrequency,
        calendar: Calendar = .current,
        max: Int = 1000
    ) -> [Date] {
        let capEnd = end ?? (calendar.date(byAdding: .year, value: 1, to: start) ?? start)
        var dates = [start]
        var current = start

        for _ in 1..<max {
            let next: Date? = {
                switch frequency {
                case .daily:   return calendar.date(byAdding: .day, value: 1, to: current)
                case .weekly:  return calendar.date(byAdding: .weekOfYear, value: 1, to: current)
                case .monthly: return calendar.date(byAdding: .month, value: 1, to: current)
                case .yearly:  return calendar.date(byAdding: .year, value: 1, to: current)
                }
            }()

            guard let next, next <= capEnd else { break }

            dates.append(next)
            current = next
        }

        return dates
    }
}
