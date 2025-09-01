//
//  HealthKitBuckets.swift
//  Wellnest
//
//  Created by 박동언 on 9/1/25.
//

import HealthKit

/// 우리가 다룰 수량형(Quantity) 메트릭
enum HKQ: CaseIterable, Sendable {
    case steps

    var quantityType: HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: .stepCount)!
    }
    var unit: HKUnit { .count() }
}

/// 통계 버킷 결과 (start~end 구간 합계값)
struct HKBucket: Sendable {
    let start: Date
    let end: Date
    let value: Double
}

/// 버킷 컬렉션
struct HKBuckets: Sendable {
    let buckets: [HKBucket]
}
