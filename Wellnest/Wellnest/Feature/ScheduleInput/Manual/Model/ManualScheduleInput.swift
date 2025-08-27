//
//  ManualScheduleInput.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/16/25.
//

import Foundation

struct ScheduleInput {
    var title: String
    var location: String?
    var detail: String?
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var backgroundColorName: String
    var repeatRuleName: String?
    var hasRepeatEndDate: Bool
    var repeatEndDate: Date?
    var alarmRuleName: String?
    var isAlarmOn: Bool
    var isCompleted: Bool
    var seriesId: String?
}
