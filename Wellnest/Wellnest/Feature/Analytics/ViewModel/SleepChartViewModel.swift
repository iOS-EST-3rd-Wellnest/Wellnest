//
//  SleepChartViewModel.swift
//  Wellnest
//
//  Created by junil on 8/14/25.
//

import Foundation

class SleepChartViewModel: ObservableObject {
    @Published var selectedPeriod: ChartPeriod = .week
    
    private let sleepData: SleepData
    
    init(sleepData: SleepData) {
        self.sleepData = sleepData
    }
    
    var currentChartData: [Double] {
        switch selectedPeriod {
        case .week:
            return sleepData.weeklySleepHours
        case .month:
            return sleepData.monthlySleepHours
        }
    }
    
    var averageSleepTime: String {
        "\(Int(sleepData.averageHours))시간 \(sleepData.averageMinutes)분"
    }
    
    var sleepQuality: String {
        "\(sleepData.sleepQuality)%"
    }
    
    var qualityChangeText: String {
        "+\(sleepData.qualityChange)%"
    }
}
