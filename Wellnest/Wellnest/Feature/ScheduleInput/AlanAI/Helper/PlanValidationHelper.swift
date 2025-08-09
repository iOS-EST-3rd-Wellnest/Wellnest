//
//  PlanValidationHelper.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import Foundation

struct PlanValidationHelper {
    static func isValidInput(
        planType: PlanType,
        singleStartTime: Date,
        singleEndTime: Date,
        multipleStartDate: Date,
        multipleEndDate: Date,
        multipleStartTime: Date,
        multipleEndTime: Date,
        selectedWeekdays: Set<Int>,
        routineStartDate: Date,
        routineEndDate: Date,
        routineStartTime: Date,
        routineEndTime: Date
    ) -> Bool {
        switch planType {
        case .single:
            return singleEndTime > singleStartTime
        case .multiple:
            return multipleEndDate > multipleStartDate && multipleEndTime > multipleStartTime
        case .routine:
            return !selectedWeekdays.isEmpty && routineEndDate > routineStartDate && routineEndTime > routineStartTime
        }
    }
}
