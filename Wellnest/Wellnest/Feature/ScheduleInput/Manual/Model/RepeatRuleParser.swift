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
        let defaultEnd: Date = {
            switch frequency {
            case .daily, .weekly:
                return calendar.date(byAdding: .year, value: 1, to: start)!   // 1년
            case .monthly:
                return calendar.date(byAdding: .year, value: 3, to: start)!   // 3년
            case .yearly:
                return calendar.date(byAdding: .year, value: 10, to: start)!  // 10년 (필요 시 조정)
            }
        }()

        let rawCapEnd = end ?? defaultEnd

        let capEnd: Date = {
            let comps = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: rawCapEnd)
            if (comps.hour ?? 0) == 0, (comps.minute ?? 0) == 0, (comps.second ?? 0) == 0, (comps.nanosecond ?? 0) == 0 {
                let sod = calendar.startOfDay(for: rawCapEnd)
                return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: sod) ?? rawCapEnd
            }
            return rawCapEnd
        }()

        var dates = [start]
        var current = start
        
//        let capEnd = end ?? (calendar.date(byAdding: .year, value: 1, to: start) ?? start)
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
