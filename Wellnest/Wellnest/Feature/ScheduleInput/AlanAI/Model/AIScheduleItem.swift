//
//  AIScheduleItem.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import Foundation

struct AIScheduleItem: Codable, Identifiable {
    let id = UUID()
    let day: String?
    let date: String?
    let time: String
    let activity: String
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case day, date, time, activity, notes
    }
}
