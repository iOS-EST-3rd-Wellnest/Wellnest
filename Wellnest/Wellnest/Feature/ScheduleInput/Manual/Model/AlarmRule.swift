//
//  AlarmRule.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import Foundation

struct AlarmRule: TagModel {
    let id = UUID()
    let name: String

    static let tags: [AlarmRule] = [
        AlarmRule(name: "10분 전"),
        AlarmRule(name: "30분 전"),
        AlarmRule(name: "1시간 전"),
        AlarmRule(name: "하루 전")
    ]
    
    var timeOffset: TimeInterval {
        switch name {
        case "10분 전":
            return -600
        case "30분 전":
            return -1800
        case "1시간 전":
            return -3600
        case "하루 전":
            return -86400
        default:
            return 0
        }
    }
}
