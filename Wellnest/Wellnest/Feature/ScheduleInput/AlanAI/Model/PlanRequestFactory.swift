//
//  PlanRequestFactory.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import Foundation

struct PlanRequestFactory {
    private static let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    
    static func createPlanRequest(
        planType: PlanType,
        selectedPreferences: Set<String>,
        singleDate: Date,
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
    ) -> PlanRequest {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        var timeframe: String

        switch planType {
        case .single:
            timeframe = """
            날짜: \(dateFormatter.string(from: singleDate))
            시간: \(timeFormatter.string(from: singleStartTime)) - \(timeFormatter.string(from: singleEndTime))
            """

        case .multiple:
            timeframe = """
            기간: \(dateFormatter.string(from: multipleStartDate)) ~ \(dateFormatter.string(from: multipleEndDate))
            운동시간: 매일 \(timeFormatter.string(from: multipleStartTime)) - \(timeFormatter.string(from: multipleEndTime))
            """

        case .routine:
            let selectedWeekdayNames = selectedWeekdays.sorted().map { weekdays[$0] }
            timeframe = """
            요일: 매주 \(selectedWeekdayNames.joined(separator: ", "))
            시간: \(timeFormatter.string(from: routineStartTime)) - \(timeFormatter.string(from: routineEndTime))
            기간: \(dateFormatter.string(from: routineStartDate)) ~ \(dateFormatter.string(from: routineEndDate))
            """
        }

        return PlanRequest(
            planType: planType,
            userGoal: "온보딩에서 설정한 목표",
            timeframe: timeframe,
            preferences: Array(selectedPreferences),
            selectedWeekdays: selectedWeekdays,
            routineStartTime: routineStartTime,
            routineEndTime: routineEndTime,
            singleStartTime: singleStartTime,
            singleEndTime: singleEndTime,
            multipleStartTime: multipleStartTime,
            multipleEndTime: multipleEndTime,
            multipleStartDate: multipleStartDate,
            multipleEndDate: multipleEndDate
        )
    }
}
