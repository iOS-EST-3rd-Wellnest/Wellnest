//
//  ExerciseData.swift
//  Wellnest
//
//  Created by junil on 8/14/25.
//

import Foundation

struct ExerciseData: Sendable {
    let stepsTodayTotal: Int
    let stepsToday3hBuckets: [TimeBucket]

    let steps7dDaily: [DailyPoint]
    let steps7dTotal: Int
    let steps7dAverage: Int

    let steps30dDaily: [DailyPoint]
    let steps30dTotal: Int
    let steps30dAverage: Int

    let isHealthKitConnected: Bool
}

