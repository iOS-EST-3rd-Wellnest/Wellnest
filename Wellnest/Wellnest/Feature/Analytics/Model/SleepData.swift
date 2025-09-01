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

enum SleepStage: Int, Codable, Hashable {
    case inBed       // 옵션: inBed는 필요 시 배경 처리에만 사용
    case asleepCore  // 가벼운 수면(light)
    case asleepDeep  // 깊은 수면(deep)
    case rem         // 렘 수면(REM)
    case awake       // 각성 상태
}

struct SleepSession: Sendable, Hashable {
    let start: Date
    let end: Date

    init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}



