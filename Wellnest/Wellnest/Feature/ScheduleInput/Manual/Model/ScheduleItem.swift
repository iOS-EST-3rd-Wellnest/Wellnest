//
//  ScheduleItem.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/3/25.
//

import SwiftUI

struct ScheduleItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let createdAt: Date
    let updatedAt: Date
    let backgroundColor: String
    let isAllDay: Bool
    let repeatRule: String?
    let hasRepeatEndDate: Bool
    let repeatEndDate: Date?
    let isCompleted: Bool
}
