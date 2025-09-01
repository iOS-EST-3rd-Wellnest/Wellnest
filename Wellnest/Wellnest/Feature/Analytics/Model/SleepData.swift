//
//  SleepData.swift
//  Wellnest
//
//  Created by junil on 8/14/25.
//

import Foundation

struct SleepData: Sendable {
    // 오늘
    let sleepTodayMinutes: Int

    // 1주 (오늘 포함 7일)
    let sleep7dDailyMinutes: [DailyPoint]
    let sleep7dTotalMinutes: Int
    let sleep7dAverageMinutes: Int

    // 1개월 (오늘 포함 30일)
    let sleep30dDailyMinutes: [DailyPoint]
    let sleep30dTotalMinutes: Int
    let sleep30dAverageMinutes: Int

    // 상태
    let isHealthKitConnected: Bool
}




