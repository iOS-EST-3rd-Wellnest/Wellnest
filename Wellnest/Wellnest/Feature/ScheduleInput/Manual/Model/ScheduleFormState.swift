//
//  ScheduleFormState.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/25/25.
//

import Foundation

struct ScheduleFormState {
    var title: String = ""
    var location: String = ""
    var detail: String = ""

    var startDate: Date = Date()
    var endDate: Date = Date().addingTimeInterval(3600)
    var isAllDay: Bool = false

    var isRepeated: Bool = false
    var selectedRepeatRule: RepeatRule? = nil
    var repeatEndMode: Mode = .none
    var repeatEndDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    var isAlarmOn: Bool = false
    var alarmRule: AlarmRule? = nil

    var selectedColorName: String = "wellnestAccentPeach"

    var hasRepeatEndDate: Bool {
        return repeatEndMode == .date
    }

    var isTextEmpty: Bool {
        title.isEmpty
    }

}
