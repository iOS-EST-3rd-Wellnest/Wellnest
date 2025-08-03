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
}
