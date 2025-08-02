//
//  AlarmRule.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import Foundation

struct AlarmRule {
    static let tags: [Tag] = Frequency.allCases.map { Tag(name: $0.label) }

    var frequency: String?

    enum Frequency: CaseIterable, Equatable, Hashable {
        case onTime, tenMinutes, halfAnHour

        var label: String {
            switch self {
            case .onTime: return "정시에"
            case .tenMinutes: return "10분 전"
            case .halfAnHour: return "30분 전"
            }
        }
    }
}
