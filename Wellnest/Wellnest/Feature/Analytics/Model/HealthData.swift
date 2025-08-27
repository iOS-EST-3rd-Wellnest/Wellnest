//
//  HealthData.swift
//  Wellnest
//
//  Created by junil on 8/14/25.
//

import Foundation

struct HealthData {
    let userName: String
    let planCompletion: PlanCompletionData
    let aiInsight: AIInsightData
    let exercise: ExerciseData
    let sleep: SleepData
}

enum ChartPeriod: String, CaseIterable {
    case today = "오늘"
    case week = "1주"
    case month = "1개월"
}

enum DataType {
    case steps
    case sleep
}
