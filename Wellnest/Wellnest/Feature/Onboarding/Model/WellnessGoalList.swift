//
//  WellnessGoalList.swift
//  Wellnest
//
//  Created by 정소이 on 8/6/25.
//

import Foundation

struct WellnessGoal: Identifiable {
    let id = UUID()
    let title: String
    var isSelected: Bool = false

    static let goals: [WellnessGoal] = [
        WellnessGoal(title: "🧘🏾  마음의 안정과 스트레스 관리"),
        WellnessGoal(title: "💪🏻  꾸준한 신체 활동 루틴 형성"),
        WellnessGoal(title: "💤  수면과 회복의 질 향상"),
        WellnessGoal(title: "🥗  건강한 식습관 형성"),
        WellnessGoal(title: "🏋🏻‍♀️  체중 감량 또는 증가"),
        WellnessGoal(title: "💬  특별히 없음")
    ]
}
