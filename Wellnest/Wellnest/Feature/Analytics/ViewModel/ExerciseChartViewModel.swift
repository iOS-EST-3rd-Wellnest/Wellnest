//
//  ExerciseChartViewModel.swift
//  Wellnest
//
//  Created by junil on 8/14/25.
//

import Foundation

class ExerciseChartViewModel: ObservableObject {
    @Published var selectedPeriod: ChartPeriod = .week

    private let exerciseData: ExerciseData

    init(exerciseData: ExerciseData) {
        self.exerciseData = exerciseData
    }

    var currentChartData: [Double] {
        switch selectedPeriod {
        case .week:
            return exerciseData.weeklySteps
        case .month:
            return exerciseData.monthlySteps
        }
    }

    var averageSteps: String {
        "\(exerciseData.averageSteps)보"
    }

    var stepsChangeText: String {
        "+\(exerciseData.stepsChange)%"
    }

    var averageCalories: String {
        "\(exerciseData.averageCalories)kcal"
    }

    var caloriesChangeText: String {
        "+\(exerciseData.caloriesChange)%"
    }
}
