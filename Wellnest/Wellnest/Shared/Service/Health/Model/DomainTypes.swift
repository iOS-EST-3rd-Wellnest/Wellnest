//
//  DomainTypes.swift
//  Wellnest
//
//  Created by 박동언 on 9/1/25.
//

import Foundation

struct DailyPoint: Sendable {
    let date: Date
    let value: Double
}

struct TimeBucket: Sendable {
    let start: Date
    let end: Date
    let value: Double
}


