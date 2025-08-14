//
//  MockHealthData.swift
//  Wellnest
//
//  Created by junil on 8/14/25.
//

import Foundation
import SwiftUI

struct MockHealthData {
    static let sampleData = HealthData(
        userName: "홍길동",
        planCompletion: PlanCompletionData(
            completedItems: 4,
            totalItems: 8
        ),
        aiInsight: AIInsightData(
            message: "운동한 날엔 수면 시간이 평균 50분 증가했어요"
        ),
        exercise: ExerciseData(
            averageSteps: 6000,
            stepsChange: 12,
            averageCalories: 450,
            caloriesChange: 8,
            weeklySteps: [3000, 5500, 4200, 7800, 6100, 5900, 8200],
            monthlySteps: [4000, 6000, 5200, 7000, 6500, 7200, 6800, 8000]
        ),
        sleep: SleepData(
            averageHours: 7,
            averageMinutes: 15,
            sleepQuality: 85,
            qualityChange: 5,
            weeklySleepHours: [6.5, 7.2, 6.8, 8.1, 7.5, 7.0, 7.8],
            monthlySleepHours: [7.0, 7.5, 6.8, 7.2, 7.8, 7.1, 6.9, 7.6]
        ),
        meditation: MeditationData(
            weeklyCount: 3,
            changeCount: 1
        )
    )
}

#Preview {
    AnalyticsView()
}
