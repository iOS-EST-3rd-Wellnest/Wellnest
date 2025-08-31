//
//  SleepData.swift
//  Wellnest
//
//  Created by junil on 8/14/25.
//

import Foundation

struct SleepData {
    let averageHours: Double
    let averageMinutes: Int
    let sleepQuality: Int
    let qualityChange: Int
    let weeklySleepHours: [Double]
    let monthlySleepHours: [Double]

    let dailySleepTimeChange: Int
    let weeklySleepTimeChange: Int
    let monthlySleepTimeChange: Int
    let dailyQualityChange: Int
    let weeklyQualityChange: Int
    let monthlyQualityChange: Int
    
    let hasSleepTimeData: Bool
    let hasSleepQualityData: Bool
    let isHealthKitConnected: Bool
}

extension SleepData {
    var defaultSleepDuration: TimeInterval {
        return 7 * 3600
    }
}
