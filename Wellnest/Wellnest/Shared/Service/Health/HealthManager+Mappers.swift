//
//  Health+Mappers.swift
//  Wellnest
//
//  Created by 박동언 on 9/1/25.
//

import Foundation

private func roundInt(_ x: Double) -> Int { Int(x.rounded()) }

private func mapDaily(_ s: DailySeries) -> [DailyPoint] {
    s.points.map { DailyPoint(date: $0.dayStart, value: $0.value) }
}

extension ExerciseData {
    static func fromDTO(_ dto: ExerciseDTO, isConnected: Bool) -> ExerciseData {
        let buckets3h = dto.todayBuckets.threeHourSteps.map {
            TimeBucket(start: $0.start, end: $0.end, value: $0.value)
        }
        return ExerciseData(
            stepsTodayTotal: roundInt(dto.todayStepsTotal),
            stepsToday3hBuckets: buckets3h,
            steps7dDaily: mapDaily(dto.steps7d),
            steps7dTotal: roundInt(dto.steps7dTotal),
            steps7dAverage: roundInt(dto.steps7dAvg),
            steps30dDaily: mapDaily(dto.steps30d),
            steps30dTotal: roundInt(dto.steps30dTotal),
            steps30dAverage: roundInt(dto.steps30dAvg),
            isHealthKitConnected: isConnected
        )
    }
}

extension SleepData {
    static func fromDTO(_ dto: SleepDTO, isConnected: Bool) -> SleepData {
        SleepData(
            sleepTodayMinutes: roundInt(dto.todayMinutes),
            sleep7dDailyMinutes: mapDaily(dto.week),
            sleep7dTotalMinutes: roundInt(dto.weekTotalMinutes),
            sleep7dAverageMinutes: roundInt(dto.weekAvgMinutes),
            sleep30dDailyMinutes: mapDaily(dto.month),
            sleep30dTotalMinutes: roundInt(dto.monthTotalMinutes),
            sleep30dAverageMinutes: roundInt(dto.monthAvgMinutes),
            isHealthKitConnected: isConnected
        )
    }
}
