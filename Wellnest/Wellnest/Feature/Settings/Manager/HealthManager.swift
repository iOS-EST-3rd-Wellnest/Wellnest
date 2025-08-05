//
//  HealthData.swift
//  Wellnest
//
//  Created by 전광호 on 8/4/25.
//

import SwiftUI
import HealthKit

@MainActor
final class HealthManager {
    let store = HKHealthStore()
    
    let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)! // 걸음 수
    let calorieCount = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)! // 소모 칼로리
    let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)! // 수면 상태
    
    /// 권한 요청
    func requestAuthorization() async throws {
        let types: Set<HKSampleType> = [stepCount, calorieCount, sleepType]
        
        try await withCheckedContinuation { continuation in
            store.requestAuthorization(toShare: [], read: types) { success, error in
                if let error {
                    print("Error: \(error)")
                }
                
                if success {
                    continuation.resume()
                }
            }
        }
    }
    
    /// 오늘 걸음 수 가져오기
    func fetchStepCount() async throws -> Int {
        try await withCheckedContinuation { continuation in
            let now = Date()
            let startDate = Calendar.current.startOfDay(for: now)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now)
            
            let query = HKStatisticsQuery(quantityType: stepCount, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error {
                    print(error)
                } else {
                    let count = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                    continuation.resume(returning: Int(count))
                }
            }
            
            store.execute(query)
        }
    }
    
    /// 오늘 소모 칼로리 가져오기
    func fetchCalorieCount() async throws -> Int {
        try await withCheckedContinuation { continuation in
            let now = Date()
            let startDate = Calendar.current.startOfDay(for: now)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: calorieCount, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error {
                    print(error)
                }
                
                if let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) {
                    continuation.resume(returning: Int(calories))
                }
            }
            
            store.execute(query)
        }
    }
    
    /// 오늘 수면시간 데이터 가져오기 (초)
    func fetchSleepDuration() async throws -> TimeInterval {
        try await withCheckedContinuation { continuation in
            let now = Date()
            let startDate = Calendar.current.startOfDay(for: now)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
            
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(sampleType: sleepType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: [sortDescriptor]) { _, results, error in
                
                guard error == nil else {
                    print("Sleep fetch error: \(error!)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let sleepSamples = results as? [HKCategorySample] ?? []
                var totalSleep: TimeInterval = 0
                
                for sample in sleepSamples {
                    // 수면 상태가 asleep일 때만 계산
                    if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                        let duration = sample.endDate.timeIntervalSince(sample.startDate)
                        totalSleep += duration
                    }
                }
                
                continuation.resume(returning: totalSleep)
            }
            
            store.execute(query)
        }
    }
}

// 건강앱과 연동 -> 걸음수, 소모 칼로리등 가져온다 -> 가져온 데이터들을 통계쪽에 시각화
// Toggle의 변환은 UserDefault에 저장
