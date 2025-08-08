//
//  HealthPlanResponse.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import Foundation

struct HealthPlanResponse: Codable, Identifiable {
    let id = UUID()
    let planType: String
    let title: String
    let description: String?
    let schedules: [AIScheduleItem]

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case title, description, schedules
    }
}
