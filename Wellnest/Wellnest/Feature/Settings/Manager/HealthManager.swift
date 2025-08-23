//
//  HealthData.swift
//  Wellnest
//
//  Created by 전광호 on 8/4/25.
//

import SwiftUI
import HealthKit

enum HealthAuthError: Error {
    case notAvailable
    case unknown(Error)
}

struct MissingSampleCheck {
    let missingCore: [HKObjectType]
    let missingOptional: [HKObjectType]
}

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
    
    // MARK: 권한 요청 관련 -
    
    /// 필수 허용 타입
    private var requiredCoreTypes: Set<HKObjectType> {
        var s = Set<HKObjectType>()
        if let step = HKObjectType.quantityType(forIdentifier: .stepCount) { s.insert(step) }
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { s.insert(energy) }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { s.insert(sleep) }
        return s
    }
    
    /// 옵셔널 허용 타입
    private var optionalTypes: Set<HKObjectType> {
        var s = Set<HKObjectType>()
        if let hr  = HKObjectType.quantityType(forIdentifier: .heartRate) { s.insert(hr) }
        if let bmi = HKObjectType.quantityType(forIdentifier: .bodyMassIndex) { s.insert(bmi) }
        if let fat = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) { s.insert(fat) }
        return s
    }
    
    /// 예외처리를 위한 수면 쓰기 타입
    private var requiredShareTypes: Set<HKSampleType> {
        var s = Set<HKSampleType>()
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { s.insert(sleep) }
        return s
    }
    
    /// 모든 읽기 타입을 포함
    private var requiredReadTypes: Set<HKObjectType> { requiredCoreTypes.union(optionalTypes) }
    
    /// 읽기 권한이 MissingSampleCheck에 포함되었는지 확인
    func authorizationSnapshotByReadProbe() async -> MissingSampleCheck {
        @Sendable func canRead(_ type: HKObjectType) async -> Bool {
            if let qt = type as? HKQuantityType {
                // 오늘~내일 범위에 대한 가벼운 샘플 쿼리
                let start = Calendar.current.startOfDay(for: Date())
                let end   = Calendar.current.date(byAdding: .day, value: 1, to: start)!
                return await probeQuantityRead(type: qt, start: start, end: end)
            } else if let ct = type as? HKCategoryType {
                let start = Calendar.current.startOfDay(for: Date())
                let end   = Calendar.current.date(byAdding: .day, value: 1, to: start)!
                return await probeCategoryRead(type: ct, start: start, end: end)
            } else {
                return false
            }
        }
        
        async let coreResults: [(HKObjectType, Bool)] = {
            await withTaskGroup(of: (HKObjectType, Bool).self, returning: [(HKObjectType, Bool)].self) { group in
                for t in await requiredCoreTypes { group.addTask { (t, await canRead(t)) } }
                var arr: [(HKObjectType, Bool)] = []
                for await r in group { arr.append(r) }
                return arr
            }
        }()
        
        async let optResults:  [(HKObjectType, Bool)] = {
            await withTaskGroup(of: (HKObjectType, Bool).self, returning: [(HKObjectType, Bool)].self) { group in
                for t in await optionalTypes { group.addTask { (t, await canRead(t)) } }
                var arr: [(HKObjectType, Bool)] = []
                for await r in group { arr.append(r) }
                return arr
            }
        }()
        
        let (core, opt) = await (coreResults, optResults)
        let missingCore     = core.filter { !$0.1 }.map { $0.0 }
        let missingOptional = opt.filter  { !$0.1 }.map { $0.0 }
        
        return MissingSampleCheck(missingCore: missingCore, missingOptional: missingOptional)
    }
    
    /// Quantity 타입의 (걸음수, 심박수, 칼로리 등) 데이터의 읽기 권한이 있는지 확인
    private func probeQuantityRead(type: HKQuantityType, start: Date, end: Date) async -> Bool {
        await withCheckedContinuation { cont in
            let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
            let q = HKSampleQuery(sampleType: type, predicate: pred, limit: 1, sortDescriptors: nil) { _, _, error in
                if let ns = error as NSError?, ns.domain == HKErrorDomain {
                    switch ns.code {
                    case HKError.errorAuthorizationDenied.rawValue,
                        HKError.errorAuthorizationNotDetermined.rawValue,
                        HKError.errorHealthDataRestricted.rawValue,
                        HKError.errorHealthDataUnavailable.rawValue:
                        cont.resume(returning: false)
                        return
                    default:
                        break
                    }
                }
                // 권한 OK 또는 단순 데이터 없음(에러 X)
                cont.resume(returning: true)
            }
            store.execute(q)
        }
    }
    
    /// Category 타입의(수면 시간) 읽기 권한이 있는지 확인
    private func probeCategoryRead(type: HKCategoryType, start: Date, end: Date) async -> Bool {
        await withCheckedContinuation { cont in
            let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
            let q = HKSampleQuery(sampleType: type, predicate: pred, limit: 1, sortDescriptors: nil) { _, _, error in
                if let ns = error as NSError?, ns.domain == HKErrorDomain {
                    switch ns.code {
                    case HKError.errorAuthorizationDenied.rawValue,
                        HKError.errorAuthorizationNotDetermined.rawValue,
                        HKError.errorHealthDataRestricted.rawValue,
                        HKError.errorHealthDataUnavailable.rawValue:
                        cont.resume(returning: false)
                        return
                    default:
                        break
                    }
                }
                cont.resume(returning: true)
            }
            store.execute(q)
        }
    }
    
    /// 권한이 필요한 상황이면 권한 요청
    func requestAuthorizationIfNeeded() async throws -> MissingSampleCheck {
        guard HKHealthStore.isHealthDataAvailable() else { throw HealthAuthError.notAvailable }
        let before = await finalAuthSnapshot()
        if before.missingCore.isEmpty { return before }
        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                store.requestAuthorization(toShare: requiredShareTypes, read: requiredReadTypes) { _, error in
                    if let error { cont.resume(throwing: error) } else { cont.resume(returning: ()) }
                }
            }
        } catch { throw HealthAuthError.unknown(error) }
        try? await Task.sleep(for: .milliseconds(200))
        
        return await finalAuthSnapshot()
    }
    
    /// 권한 허용 최종 스냅샷
    func finalAuthSnapshot() async -> MissingSampleCheck {
        var missingCore: [HKObjectType] = []
        var missingOptional: [HKObjectType] = []
        
        // 수면 쓰기 권한으로 예외처리
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            let writeStatus = store.authorizationStatus(for: sleep)
            if writeStatus != .sharingAuthorized {
                missingCore.append(sleep)
            }
        }
        
        // 나머지 권한 확인
        for t in requiredCoreTypes {
            if (t as? HKCategoryType) == HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                continue // 수면은 위에서 판정
            }
            let can = await canReadByProbe(t)
            if !can { missingCore.append(t) }
        }
        
        // 옵셔널도 프로브로 참고
        for t in optionalTypes {
            let can = await canReadByProbe(t)
            if !can { missingOptional.append(t) }
        }
        
        return MissingSampleCheck(missingCore: missingCore, missingOptional: missingOptional)
    }
    
    private func canReadByProbe(_ type: HKObjectType) async -> Bool {
        if let qt = type as? HKQuantityType {
            let start = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let end   = Date()
            return await probeQuantityRead(type: qt, start: start, end: end)
        } else if let ct = type as? HKCategoryType {
            let start = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            let end   = Date()
            return await probeCategoryRead(type: ct, start: start, end: end)
        }
        return false
    }
    
    /// 데이터 읽기 권한 요청
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthAuthError.notAvailable
        }
        
        let toRead = requiredReadTypes
        
        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                store.requestAuthorization(toShare: nil, read: toRead) { success, error in
                    if let error { cont.resume(throwing: error); return }
                    cont.resume(returning: ())
                }
            }
        } catch {
            throw HealthAuthError.unknown(error)
        }
        
        // 실제 최종 상태 확인
        let missingCore = requiredCoreTypes.filter { store.authorizationStatus(for: $0) != .sharingAuthorized }
        if missingCore.isEmpty {
            throw HealthAuthError.notAvailable
        }
    }
    
    
    // MARK: 오늘 측정 데이터 -
    
    /// 오늘 걸음 수 가져오기
    func fetchStepCount() async throws -> Int {
        guard let stepCount else {
            return 0
        }
        
        return await withCheckedContinuation { continuation in
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
        
        return await withCheckedContinuation { continuation in
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
        
        return await withCheckedContinuation { continuation in
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
        
        return await withCheckedContinuation { continuation in
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
        
        return await withCheckedContinuation { continuation in
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
        
        return await withCheckedContinuation { continuation in
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

extension HealthManager {
    
    // MARK: - 어제부터 지난 1년간의 데이터 (걸음수, 칼로리, 심박수, 수면시간)
    
    /// 일자별 요약
    struct DailyMetric {
        let dayStart: Date      // 해당 날짜 00:00
        let steps: Int          // 걸음(합계)
        let kcal: Int           // 활동 칼로리(kcal, 합계)
        let avgHR: Int          // 평균 심박수(bpm)
        let sleepMinutes: Int   // 수면(분)
    }
    
    /// 어제까지 1년 범위
    private func lastYearExcludingToday() -> DateInterval {
        let cal = Calendar.current
        let today0 = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .year, value: -1, to: today0)! //1년 전
        return DateInterval(start: start, end: today0) // 어제까지 포함
    }
    
    /// 수량형(걸음/칼로리/심박) 일별 값
    private func dailyStatistics(
        type: HKQuantityType,
        unit: HKUnit,
        options: HKStatisticsOptions,
        range: DateInterval
    ) async throws -> [(dayStart: Date, value: Double)] {
        try await withCheckedThrowingContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: range.start, end: range.end)
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: options,
                anchorDate: Calendar.current.startOfDay(for: range.start),
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, collection, error in
                if let error { cont.resume(throwing: error); return }
                guard let collection else { cont.resume(returning: []); return }
                
                var out: [(Date, Double)] = []
                collection.enumerateStatistics(from: range.start, to: range.end) { stats, _ in
                    let v: Double =
                    options.contains(.cumulativeSum)      ? (stats.sumQuantity()?.doubleValue(for: unit) ?? 0) :
                    options.contains(.discreteAverage)    ? (stats.averageQuantity()?.doubleValue(for: unit) ?? 0) :
                    options.contains(.discreteMostRecent) ? (stats.mostRecentQuantity()?.doubleValue(for: unit) ?? 0) : 0
                    out.append((Calendar.current.startOfDay(for: stats.startDate), v))
                }
                
                // 누락 일자는 0으로 채우기
                let days = daysInRange(range, calendar: .current)
                let filled = days.map { day in
                    (day, out.first(where: { $0.0 == day })?.1 ?? 0)
                }
                cont.resume(returning: filled)
            }
            self.store.execute(query)
        }
    }
    
    /// 수면: 범위 내 샘플을 가져와 전날 18시 ~ 오늘 18시의 시간으로 집계
    private func dailySleepMinutes(
        range: DateInterval,
        sleepSampleType: HKSampleType,
        anchorHour: Int = 18
    ) async throws -> [(dayStart: Date, value: Double)] {
        try await withCheckedThrowingContinuation { cont in
            let cal = Calendar.current
            // 시프트 오프셋(예: 18시 앵커 → -18시간 시프트)
            let offset = TimeInterval(-anchorHour * 3600)
            
            // 시프트된 구간: [start - anchor, end - anchor)
            let shiftedRange = DateInterval(
                start: range.start.addingTimeInterval(offset),
                end:   range.end.addingTimeInterval(offset)
            )
            
            // 원본 타임라인에서 필요한 샘플만 가져오도록 프레디케이트 범위 설정
            let predicate = HKQuery.predicateForSamples(
                withStart: shiftedRange.start,
                end: shiftedRange.end
            )
            
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let q = HKSampleQuery(
                sampleType: sleepSampleType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, results, error in
                if let error { cont.resume(throwing: error); return }
                let samples = (results as? [HKCategorySample]) ?? []
                
                let asleep = Set([
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ])
                
                var bucket: [Date: TimeInterval] = [:]
                
                // 각 샘플을 시프트된 타임라인 으로 옮겨서 자정 단위로 분할/합산
                for s in samples where asleep.contains(s.value) {
                    var cur = s.startDate.addingTimeInterval(offset)
                    let end = s.endDate.addingTimeInterval(offset)
                    
                    cur = max(cur, shiftedRange.start)
                    let clampedEnd = min(end, shiftedRange.end)
                    
                    while cur < clampedEnd {
                        let dayStartShifted = cal.startOfDay(for: cur)
                        let nextBoundary = cal.date(byAdding: .day, value: 1, to: dayStartShifted)!
                        let segmentEnd = min(clampedEnd, nextBoundary)
                        bucket[dayStartShifted, default: 0] += segmentEnd.timeIntervalSince(cur)
                        cur = segmentEnd
                    }
                }
                
                // 결과 일자 목록(누락일 0 채우기)
                let daysShifted = daysInRange(shiftedRange, calendar: cal)
                let addDay = (anchorHour % 24 == 0) ? 0 : 1
                
                let result = daysShifted.map { dayStartShifted -> (dayStart: Date, value: Double) in
                    let labelDayStart = cal.date(byAdding: .day, value: addDay, to: dayStartShifted)! // ← 핵심
                    let minutes = (bucket[dayStartShifted] ?? 0) / 60.0
                    return (dayStart: labelDayStart, value: minutes)
                }
                
                cont.resume(returning: result)
            }
            
            self.store.execute(q)
        }
    }
    
    
    /// 어제부터 지난 1년간의 "일별" 걸음/칼로리/평균심박/수면(분)
    func fetchLastYearFromYesterday() async throws -> [DailyMetric] {
        let range = lastYearExcludingToday()
        let cal = Calendar.current
        
        guard
            let stepType = stepCount,
            let kcalType = calorieCount,
            let hrType = heartRateType,
            let sleepType = sleepTime as? HKSampleType
        else { return [] }
        
        async let stepsArr = dailyStatistics(
            type: stepType, unit: .count(), options: .cumulativeSum, range: range
        )
        async let kcalArr  = dailyStatistics(
            type: kcalType, unit: .kilocalorie(), options: .cumulativeSum, range: range
        )
        async let hrArr    = dailyStatistics(
            type: hrType, unit: HKUnit(from: "count/min"), options: .discreteAverage, range: range
        )
        async let sleepArr = dailySleepMinutes(range: range, sleepSampleType: sleepType)
        
        let (sA, kA, hA, slA) = try await (stepsArr, kcalArr, hrArr, sleepArr)
        
        // 날짜 키로 병합
        var map: [Date: DailyMetric] = [:]
        for day in daysInRange(range, calendar: cal) {
            let s  = Int(sA.first(where: { $0.dayStart == day })?.value ?? 0)
            let kc = Int(kA.first(where: { $0.dayStart == day })?.value ?? 0)
            let hr = Int((hA.first(where: { $0.dayStart == day })?.value ?? 0).rounded())
            let sl = Int(slA.first(where: { $0.dayStart == day })?.value ?? 0)
            map[day] = DailyMetric(dayStart: day, steps: s, kcal: kc, avgHR: hr, sleepMinutes: sl)
        }
        
        // 오름차순 정렬로 반환
        return daysInRange(range, calendar: cal).compactMap { map[$0] }
    }
}

@inline(__always)
func daysInRange(_ range: DateInterval, calendar cal: Calendar = .current) -> [Date] {
    var out: [Date] = []
    var cur = cal.startOfDay(for: range.start)
    while cur < range.end {
        out.append(cur)
        cur = cal.date(byAdding: .day, value: 1, to: cur)!
    }
    return out
}


extension Notification.Name {
    static let healthDataDidUpdate = Notification.Name("healthDataDidUpdate")
}
