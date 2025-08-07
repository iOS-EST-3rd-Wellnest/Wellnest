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
    static let shared = HealthManager()
    
    let store = HKHealthStore()
    
    let stepCount: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .stepCount) // 걸음 수
    let calorieCount: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) // 소모 칼로리
    let sleepTime: HKObjectType? = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) // 수면 시간
    let heartRateType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .heartRate) // 평균 심박수
    let bmiType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex) // BMI
    let bodyFatType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) // 체지방량
    
    /// 데이터 읽기 권한 요청
    func requestAuthorization() async throws {
        guard let stepCount, let calorieCount, let sleepTime, let heartRateType, let bmiType, let bodyFatType else {
            print("Error: HealthKit not available")
            return
        }
        let types: Set = [stepCount, calorieCount, sleepTime, heartRateType, bmiType, bodyFatType]
        
        try await withCheckedContinuation { continuation in
            store.requestAuthorization(toShare: [], read: types) { success, error in
                if let error {
                    print("Error: \(error)")
                    return
                }
                
                if success {
                    continuation.resume()
                }
            }
        }
    }
    
    /// 오늘 걸음 수 가져오기
    func fetchStepCount() async throws -> Int {
        guard let stepCount else {
            return 0
        }
        
        return try await withCheckedContinuation { continuation in
            let now = Date()
            let startDate = Calendar.current.startOfDay(for: now)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now)
            
            let query = HKStatisticsQuery(
                quantityType: stepCount,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
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
        guard let calorieCount else {
            return 0
        }
        
        return try await withCheckedContinuation { continuation in
            let now = Date()
            let startDate = Calendar.current.startOfDay(for: now)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
            
            let query = HKStatisticsQuery(
                quantityType: calorieCount,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
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
    
    /// 오늘 수면시간 가져오기
    func fetchSleepDuration() async throws -> TimeInterval {
        guard let sleepTime else {
            return 0
        }
        
        return try await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .hour, value: -24, to: endDate)!
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: sleepTime as! HKSampleType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                guard error == nil else {
                    print("Sleep fetch error: \(error!)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let sleepSamples = results as? [HKCategorySample] ?? []
                var totalSleep: TimeInterval = 0
                
                for sample in sleepSamples {
                    // asleep 상태 모두 포함
                    if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue {
                        totalSleep += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
                
                continuation.resume(returning: totalSleep)
            }
            
            store.execute(query)
        }
    }
    
    /// 오늘 심박수 평균 값
    func fetchAverageHeartRate() async throws -> Int {
        guard let heartRateType else {
            return 0
        }
        
        return try await withCheckedContinuation { continuation in
            let now = Date()
            let startDate = Calendar.current.startOfDay(for: now)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
            
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage  // 평균 심박수
            ) { _, result, error in
                guard error == nil else {
                    print("심박수 오류:", error!)
                    continuation.resume(returning: 0)
                    return
                }
                
                let average = result?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
                continuation.resume(returning: Int(average))
            }
            
            store.execute(query)
        }
    }
    
    /// 최근 BMI값
    func fetchBMI() async throws -> Double {
        guard let bmiType else {
            return 0.0
        }
        
        return try await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(sampleType: bmiType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, result, error in
                if let error {
                    print("BMI Error:", error)
                    return
                }
                
                guard let sample = result?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0.0)
                    return
                }
                
                let bmi = sample.quantity.doubleValue(for: HKUnit.count())
                continuation.resume(returning: bmi)
            }
            
            store.execute(query)
        }
    }
    
    /// 최근 체지방률
    func fetchBodyFatPercentage() async throws -> Double {
        guard let bodyFatType else {
            return 0.0
        }
        
        return try await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(sampleType: bodyFatType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, result, error in
                if let error {
                    print("Body Fat Error:", error)
                }
                
                guard let smaple = result?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0.0)
                    return
                }
                
                let bodyFatPercentage = smaple.quantity.doubleValue(for: HKUnit.percent()) * 100
                continuation.resume(returning: bodyFatPercentage)
            }
            
            store.execute(query)
        }
    }
    
    /// 건강 앱 데이터가 업데이트 될 때 호출
    func startObservingUpdates(for type: HKSampleType) {
            let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completionHandler, error in
                if let error = error {
                    print("앱 데이터 불러오기 실패: \(error.localizedDescription)")
                    return
                }

                print("건강 앱 데이터 변경: \(type.identifier)")
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .healthDataDidUpdate, object: type)
                    completionHandler()
                }
            }

            store.execute(query)
        }
}

extension Notification.Name {
    static let healthDataDidUpdate = Notification.Name("healthDataDidUpdate")
}
