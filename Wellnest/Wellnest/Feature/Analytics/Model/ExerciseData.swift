//
//  ExerciseData.swift
//  Wellnest
//
//  Created by junil on 8/14/25.
//

import Foundation

struct ExerciseData {
    let averageSteps: Int
    let stepsChange: Int
    let averageCalories: Int
    let caloriesChange: Int
    let weeklySteps: [Double]
    let monthlySteps: [Double]

    let dailyStepsChange: Int
    let weeklyStepsChange: Int
    let monthlyStepsChange: Int
    let dailyCaloriesChange: Int
    let weeklyCaloriesChange: Int
    let monthlyCaloriesChange: Int
    
    let hasStepsData: Bool
    let hasCaloriesData: Bool
    let isHealthKitConnected: Bool
}

extension ExerciseData {
    var defaultTodaySteps: Int {
        return 7203
    }
    
    var defaultTodayCalories: Int {
        return 2120
    }
}
