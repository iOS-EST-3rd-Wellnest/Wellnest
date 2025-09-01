//
//  HealthManager+SleepBuckets.swift
//  Wellnest
//
//  Created by 박동언 on 9/1/25.
//

import Foundation
import HealthKit

extension HealthManager {

    /// 수면을 앵커(기본 18시) 기준으로 하루를 구분하여 **일별 분(min)** 버킷 생성
    /// - Parameters:
    ///   - reference: 끝 시각 기준(보통 지금)
    ///   - days: 포함 일수(7 = 오늘포함 7일)
    ///   - anchorHour: 하루 경계(기본 18시 → 18~다음날 18시)
    func sleepDailyMinutesBuckets(
        reference: Date = Date(),
        days: Int,
        anchorHour: Int = 18
    ) async throws -> HKBuckets {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return HKBuckets(buckets: [])
        }

        let cal = Calendar.current
        // 앵커 시프트 (예: 18시는 -18시간 시프트 후 자정 경계로 집계)
        let shift = TimeInterval(-anchorHour * 3600)

        let end = reference.addingTimeInterval(shift)
        let start = cal.date(byAdding: .day, value: -(days - 1), to: cal.startOfDay(for: end))!

        let pred = HKQuery.predicateForSamples(withStart: start, end: end)
        return try await withCheckedThrowingContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let q = HKSampleQuery(sampleType: sleepType, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, results, error in
                if let error { return cont.resume(throwing: error) }
                let samples = (results as? [HKCategorySample]) ?? []

                let asleep = Set([
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ])

                var acc: [Date: TimeInterval] = [:]

                for s in samples where asleep.contains(s.value) {
                    var cur = s.startDate.addingTimeInterval(shift)
                    let limit = s.endDate.addingTimeInterval(shift)

                    var curClamped = max(cur, start)
                    let limitClamped = min(limit, end)

                    while curClamped < limitClamped {
                        let day0 = cal.startOfDay(for: curClamped)
                        let next = cal.date(byAdding: .day, value: 1, to: day0)!
                        let segEnd = min(limitClamped, next)
                        acc[day0, default: 0] += segEnd.timeIntervalSince(curClamped)
                        curClamped = segEnd
                    }
                }

                // 누락 일 0 채우기 + 레이블일 보정(앵커 18시 → 실제 라벨은 +1일)
                let day0List: [Date] = {
                    var out: [Date] = []
                    var p = start
                    while p <= end {
                        out.append(p)
                        p = cal.date(byAdding: .day, value: 1, to: p)!
                    }
                    return out
                }()

                let labeledShift = (anchorHour % 24 == 0) ? 0 : 1
                var buckets: [HKBucket] = []
                for d0 in day0List {
                    let minutes = (acc[d0] ?? 0) / 60.0
                    let labelStart = cal.date(byAdding: .day, value: labeledShift, to: d0)! // 표기용 날짜
                    let labelEnd   = cal.date(byAdding: .day, value: labeledShift, to: cal.date(byAdding: .day, value: 1, to: d0)!)!
                    buckets.append(.init(start: labelStart, end: labelEnd, value: minutes))
                }

                cont.resume(returning: HKBuckets(buckets: buckets))
            }
            self.store.execute(q)
        }
    }
}
