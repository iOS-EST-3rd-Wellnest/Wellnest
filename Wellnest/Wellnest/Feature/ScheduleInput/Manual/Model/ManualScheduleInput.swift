//
//  ManualScheduleInput.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/16/25.
//

import Foundation

struct ScheduleInput {
    let title: String
    let location: String
    let detail: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let backgroundColorName: String

    // 반복
    let isRepeat: Bool
    let repeatRuleName: String?        // UI의 태그 이름(없으면 nil)
    let hasRepeatEndDate: Bool
    let repeatEndDate: Date?

    // 알람
    let alarmRuleName: String?
    let isAlarmOn: Bool

    // 완료 플래그(신규는 보통 false)
    let isCompleted: Bool
}
