//
//  StatsMath.swift
//  Wellnest
//
//  Created by 박동언 on 9/1/25.
//

import Foundation

@inline(__always)
func sum(_ arr: [Double]) -> Double { arr.reduce(0, +) }

@inline(__always)
func avg(_ arr: [Double]) -> Double {
    guard !arr.isEmpty else { return 0 }
    return sum(arr) / Double(arr.count)
}

@inline(__always)
func seriesValues(_ buckets: HKBuckets) -> [Double] {
    buckets.buckets.map(\.value)
}

@inline(__always)
func seriesDates(_ buckets: HKBuckets) -> [Date] {
    buckets.buckets.map(\.start)
}



/// 일별 버킷을 우리 DTO의 `DailySeries`로 변환
func toDailySeries(_ buckets: HKBuckets) -> DailySeries {
    DailySeries(points: buckets.buckets.map { ($0.start, $0.value) })
}
