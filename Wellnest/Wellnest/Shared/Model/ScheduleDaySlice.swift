//
//  ScheduleDaySlice.swift
//  Wellnest
//
//  Created by 박동언 on 8/23/25.
//

import SwiftUI

struct ScheduleDaySlice: Identifiable {
    let id = UUID()
    let item: ScheduleItem
    let date: Date
    let displayStart: Date?
    let displayEnd: Date?
    let isAllDayForThatDate: Bool
}
