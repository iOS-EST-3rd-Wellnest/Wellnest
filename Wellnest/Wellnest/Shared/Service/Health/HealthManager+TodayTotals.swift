//
//  HealthManager+TodayTotals.swift
//  Wellnest
//
//  Created by 박동언 on 9/1/25.
//

import Foundation
import HealthKit

extension HealthManager {

    /// 오늘 수량형 총합 (걸음/활동에너지)
    func quantityTodayTotal(_ metric: HKQ) async -> Double {
        let qt   = metric.quantityType      // 이제 steps만 존재
        let unit = metric.unit
        let cal  = Calendar.current
        let now  = Date()
        let start = cal.startOfDay(for: now)

        return await withCheckedContinuation { cont in
            let pred = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)
            let q = HKStatisticsQuery(quantityType: qt,
                                      quantitySamplePredicate: pred,
                                      options: .cumulativeSum) { _, stats, error in
                if let ns = error as NSError? {
                    if ns.domain == HKErrorDomain, ns.code == 11 {
                        cont.resume(returning: 0); return
                    }
                    #if DEBUG
                    print("❌ quantityTodayTotal(\(qt.identifier)) error: \(ns.localizedDescription)")
                    #endif
                    cont.resume(returning: 0); return
                }
                let v = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                cont.resume(returning: v)
            }
            self.store.execute(q)
        }
    }

    /// 오늘 수면(분) — 위 수면 버킷 헬퍼를 활용
    func sleepTodayMinutes(anchorHour: Int = 18) async throws -> Double {
        // 더 넓은 범위로 조회 (어제 18시 ~ 오늘 18시)
        let cal = Calendar.current
        let now = Date()
        let today18 = cal.date(bySettingHour: anchorHour, minute: 0, second: 0, of: now) ?? now
        let yesterday18 = cal.date(byAdding: .day, value: -1, to: today18) ?? now

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("❌ sleepType not available")
            return 0
        }

        return try await withCheckedThrowingContinuation { cont in
            let pred = HKQuery.predicateForSamples(withStart: yesterday18, end: today18)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

            let q = HKSampleQuery(
                sampleType: sleepType,
                predicate: pred,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, results, error in
                if let error {
                    print("❌ sleepTodayMinutes error: \(error)")
                    return cont.resume(throwing: error)
                }

                let samples = (results as? [HKCategorySample]) ?? []

                let asleepValues = Set([
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ])

                var totalMinutes: TimeInterval = 0
                for sample in samples where asleepValues.contains(sample.value) {
                    totalMinutes += sample.endDate.timeIntervalSince(sample.startDate)
                }

                let minutes = totalMinutes / 60.0
                cont.resume(returning: minutes)
            }

            self.store.execute(q)
        }
    }

    @inline(__always)
    private func isActiveEnergy(_ qt: HKQuantityType) -> Bool {
        guard let active = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return false }
        return qt == active
    }

    private func todayWorkoutTotalEnergyKcal(start: Date, end: Date) async -> Double {
        let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let workoutType = HKObjectType.workoutType()

        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: workoutType,
                                  predicate: pred,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: [sort]) { _, results, error in
                if let ns = error as NSError? {
                    if ns.domain == HKErrorDomain, ns.code == 11 {
                        cont.resume(returning: 0); return
                    }
                    #if DEBUG
                    print("❌ Workout fallback error: \(ns.localizedDescription)")
                    #endif
                    cont.resume(returning: 0); return
                }
                let workouts = (results as? [HKWorkout]) ?? []
                let total = workouts
                    .compactMap { $0.totalEnergyBurned?.doubleValue(for: .kilocalorie()) }
                    .reduce(0, +)
                cont.resume(returning: total)
            }
            self.store.execute(q)
        }
    }
}
