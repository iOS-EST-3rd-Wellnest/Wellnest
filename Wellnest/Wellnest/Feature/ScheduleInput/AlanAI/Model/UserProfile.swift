//
//  UserProfile.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import Foundation

struct UserProfile {
    let gender: String
    let age: Int
    let height: Int
    let weight: Int
    let sleepSchedule: String
    let exerciseTimeSlot: String
    let preferredExercises: [String]
    let exerciseIntensity: String

    static let `default` = UserProfile(
        gender: "남성",
        age: 25,
        height: 180,
        weight: 90,
        sleepSchedule: "오전 12시 ~ 오전 7시 (7시간)",
        exerciseTimeSlot: "오후 8시 ~ 오후 11시",
        preferredExercises: ["유산소", "근력운동", "요가", "필라테스", "수영", "사이클링"],
        exerciseIntensity: "보통"
    )
}
