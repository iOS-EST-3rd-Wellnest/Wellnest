//
//  HealthDTO.swift
//  Wellnest
//
//  Created by 박동언 on 9/1/25.
//

import Foundation

struct DailySeries: Sendable {
    /// dayStart 자정
    var points: [(dayStart: Date, value: Double)]
}

struct TodayBuckets: Sendable {
    var threeHourSteps: [HKBucket]   // 오늘 3시간 단위 걸음수
}

struct ExerciseDTO: Sendable {
    // Today
    var todayStepsTotal: Double
    var todayBuckets: TodayBuckets

    // 7 days (rolling)
    var steps7d: DailySeries
    var steps7dTotal: Double
    var steps7dAvg: Double

    // 30 days (rolling)
    var steps30d: DailySeries
    var steps30dTotal: Double
    var steps30dAvg: Double
}

struct SleepDTO: Sendable {
    /// 분 단위(min)
    var todayMinutes: Double
    var week: DailySeries
    var weekTotalMinutes: Double
    var weekAvgMinutes: Double
    var month: DailySeries
    var monthTotalMinutes: Double
    var monthAvgMinutes: Double
}
