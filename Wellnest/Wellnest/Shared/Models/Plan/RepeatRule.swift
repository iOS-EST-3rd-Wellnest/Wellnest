//
//  RepeatRule.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import Foundation

struct RepeatRule {
    static let tags: [Tag] = Frequency.allCases.map { Tag(name: $0.label) }

    var endDate: Date?
    var frequency: String?
    // 반복 주기 enum
    enum Frequency: CaseIterable, Equatable, Hashable {
        case daily, weekly, monthly, yearly

        var label: String {
            switch self {
            case .daily: return "매일"
            case .weekly: return "매주"
            case .monthly: return "매월"
            case .yearly: return "매년"
            }
        }
    }
}
