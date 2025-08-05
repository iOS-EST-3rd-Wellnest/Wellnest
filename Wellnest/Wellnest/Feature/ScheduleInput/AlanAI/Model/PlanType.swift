//
//  PlanType.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import Foundation

enum PlanType: String, CaseIterable {
    case single = "single"
    case multiple = "multiple"
    case routine = "routine"
    
    var displayName: String {
        switch self {
        case .single:
            return "단일 일정"
        case .multiple:
            return "여러 일정"
        case .routine:
            return "루틴"
        }
    }
    
    var icon: String {
        switch self {
        case .single: return "calendar.badge.plus"
        case .multiple: return "calendar"
        case .routine: return "repeat"
        }
    }
}
