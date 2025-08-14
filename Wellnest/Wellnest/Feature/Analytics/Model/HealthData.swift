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
    let meditation: MeditationData
}

enum ChartPeriod: String, CaseIterable {
    case week = "1주"
    case month = "1개월"
}
