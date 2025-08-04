//
//  ScheduleItem.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/3/25.
//

import Foundation

struct ScheduleItem: Identifiable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
}
