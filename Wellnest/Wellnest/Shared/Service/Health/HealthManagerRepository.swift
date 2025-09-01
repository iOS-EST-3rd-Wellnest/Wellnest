//
//  HealthManagerRepository.swift
//  Wellnest
//
//  Created by 박동언 on 9/1/25.
//

import Foundation
import HealthKit


struct HealthConnection: Sendable {
    let stepsGranted: Bool         // 걸음 읽기 가능?
    let sleepGranted: Bool         // 수면 읽기/쓰기(예외) 가능?

    var anyGranted: Bool { stepsGranted || sleepGranted }
}

actor HealthManagerRepository {
    static let shared = HealthManagerRepository()
    private let manager = HealthManager.shared

    func connection() async -> HealthConnection {
        let snap = await manager.finalAuthSnapshot()

        let stepID   = HKQuantityTypeIdentifier.stepCount.rawValue
        let sleepID  = HKCategoryTypeIdentifier.sleepAnalysis.rawValue

        let missing = Set(snap.missingCore.map(\.identifier) + snap.missingOptional.map(\.identifier))

        let stepsGranted = !missing.contains(stepID)
        let sleepGranted = !missing.contains(sleepID)

        return .init(stepsGranted: stepsGranted, sleepGranted: sleepGranted)
    }

    /// 걸음 + 수면만 로드
    func loadAllWithErrorHandling(reference: Date = Date()) async throws
        -> (exercise: ExerciseDTO, sleep: SleepDTO, connection: HealthConnection) {

        async let connTask = connection()

        // 걸음(오늘 합계 / 3시간 버킷 / 7일 / 30일)
        let todayStepsTotal = await safeExecute {
            try await manager.quantityTodayTotal(.steps)
        } ?? 0

        let today3hSteps = await safeExecute {
            try await manager.quantityBucketsTodayByHour(metric: .steps, hourInterval: 3)
        } ?? HKBuckets(buckets: [])

        let steps7dBuckets = await safeExecute {
            try await manager.quantityDailyBucketsLast7Days(metric: .steps, reference: reference)
        } ?? HKBuckets(buckets: [])

        let steps30dBuckets = await safeExecute {
            try await manager.quantityDailyBucketsLast30Days(metric: .steps, reference: reference)
        } ?? HKBuckets(buckets: [])

        // 수면(오늘 / 7일 / 30일)
        let sleepTodayMin = await safeExecute {
            try await manager.sleepTodayMinutes(anchorHour: 18)
        } ?? 0

        let sleep7dBuckets = await safeExecute {
            try await manager.sleepDailyMinutesBuckets(reference: reference, days: 7, anchorHour: 18)
        } ?? HKBuckets(buckets: [])

        let sleep30dBuckets = await safeExecute {
            try await manager.sleepDailyMinutesBuckets(reference: reference, days: 30, anchorHour: 18)
        } ?? HKBuckets(buckets: [])

        let conn = await connTask

        print("🔍 로드 결과:")
        print("  - 오늘 걸음: \(todayStepsTotal)")
        print("  - 7일 걸음 데이터 개수: \(steps7dBuckets.buckets.count)")
        print("  - 30일 걸음 데이터 개수: \(steps30dBuckets.buckets.count)")
        print("  - 오늘 수면: \(sleepTodayMin)분")

        let exercise = ExerciseDTO(
            todayStepsTotal: todayStepsTotal,
            todayBuckets: TodayBuckets(threeHourSteps: today3hSteps.buckets),
            steps7d: toDailySeries(steps7dBuckets),
            steps7dTotal: sum(seriesValues(steps7dBuckets)),
            steps7dAvg: avg(seriesValues(steps7dBuckets)),
            steps30d: toDailySeries(steps30dBuckets),
            steps30dTotal: sum(seriesValues(steps30dBuckets)),
            steps30dAvg: avg(seriesValues(steps30dBuckets))
        )

        let sleep = SleepDTO(
            todayMinutes: sleepTodayMin,
            week: toDailySeries(sleep7dBuckets),
            weekTotalMinutes: sum(seriesValues(sleep7dBuckets)),
            weekAvgMinutes: avg(seriesValues(sleep7dBuckets)),
            month: toDailySeries(sleep30dBuckets),
            monthTotalMinutes: sum(seriesValues(sleep30dBuckets)),
            monthAvgMinutes: avg(seriesValues(sleep30dBuckets))
        )

        return (exercise, sleep, conn)
    }

    private func safeExecute<T>(_ operation: () async throws -> T) async -> T? {
        do { return try await operation() }
        catch {
            print("❌ safeExecute 실패: \(error.localizedDescription)")
            return nil
        }
    }
}
