//
//  ScheduleCreationType.swift
//  Wellnest
//
//  Created by 박동언 on 8/3/25.
//


enum ScheduleCreationType: Identifiable {
    case createByAI
    case createByUser

    var id: String {
        switch self {
        case .createByAI: "AI"
        case .createByUser: "User"
        }
    }
}
