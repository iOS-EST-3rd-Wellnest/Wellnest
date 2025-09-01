//
//  HealthManager+Buckets.swift
//  Wellnest
//
//  Created by 박동언 on 9/1/25.
//

import Foundation
import HealthKit

extension HealthManager {

    /// 임의 간격(intervalComponents)으로 수량형 합계를 버킷팅해 가져오기
    /// - Parameters:
    ///   - metric: 걸음/활동에너지 등
    ///   - start: 시작 시각(포함)
    ///   - end: 종료 시각(미만 권장)
    ///   - intervalComponents: 버킷 간격 (예: DateComponents(hour: 3), DateComponents(day: 1))
    ///   - anchor: 앵커(일반적으로 end의 자정). nil이면 end의 자정 사용
    /// - Returns: [버킷]
    func quantityBuckets(
        metric: HKQ,
        start: Date,
        end: Date,
        intervalComponents: DateComponents,
        anchor: Date? = nil
    ) async throws -> HKBuckets {

        let qt = metric.quantityType
        let unit = metric.unit
        let cal  = Calendar.current
        let anchorDate = anchor ?? cal.startOfDay(for: end)

        return try await withCheckedThrowingContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let q = HKStatisticsCollectionQuery(
                quantityType: qt,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: intervalComponents
            )

            q.initialResultsHandler = { _, collection, error in
                if let error { return cont.resume(throwing: error) }
                guard let collection else { return cont.resume(returning: HKBuckets(buckets: [])) }

                var out: [HKBucket] = []
                collection.enumerateStatistics(from: start, to: end) { stats, _ in
                    let val = stats.sumQuantity()?.doubleValue(for: unit) ?? 0
                    out.append(HKBucket(start: stats.startDate, end: stats.endDate, value: val))
                }
                cont.resume(returning: HKBuckets(buckets: out))
            }

            self.store.execute(q)
        }
    }

    /// "오늘 N시간 간격" 버킷 (예: 3시간 단위)
    func quantityBucketsTodayByHour(
        metric: HKQ,
        hourInterval: Int
    ) async throws -> HKBuckets {
        let cal = Calendar.current
        let now = Date()
        let start = cal.startOfDay(for: now)
        let end   = now
        var comp = DateComponents()
        comp.hour = hourInterval
        return try await quantityBuckets(
            metric: metric,
            start: start,
            end: end,
            intervalComponents: comp,
            anchor: start
        )
    }

    /// 오늘 포함 1주(=최근 7일) **일별** 버킷
    func quantityDailyBucketsLast7Days(
        metric: HKQ,
        reference: Date = Date()
    ) async throws -> HKBuckets {
        let cal = Calendar.current
        let end = reference
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: end))!
        return try await quantityBuckets(
            metric: metric,
            start: start,
            end: end,
            intervalComponents: DateComponents(day: 1),
            anchor: cal.startOfDay(for: end)
        )
    }

    /// 오늘 포함 1개월(=최근 30일) **일별** 버킷
    func quantityDailyBucketsLast30Days(
        metric: HKQ,
        reference: Date = Date()
    ) async throws -> HKBuckets {
        let cal = Calendar.current
        let end = reference
        let start = cal.date(byAdding: .day, value: -29, to: cal.startOfDay(for: end))!
        return try await quantityBuckets(
            metric: metric,
            start: start,
            end: end,
            intervalComponents: DateComponents(day: 1),
            anchor: cal.startOfDay(for: end)
        )
    }
}
