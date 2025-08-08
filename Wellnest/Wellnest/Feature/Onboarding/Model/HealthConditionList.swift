//
//  HealthConditionList.swift
//  Wellnest
//
//  Created by 정소이 on 8/6/25.
//

import Foundation

struct HealthCondition: SelectableItem {
    let id = UUID()
    let icon: String?
    let category: String
    var isSelected: Bool = false

    static let conditions: [HealthCondition] = [
        HealthCondition(icon: "😀", category: "특별히 없음"),
        HealthCondition(icon: "🩸", category: "당뇨"),
        HealthCondition(icon: "🫀", category: "고혈압/부정맥"),
        HealthCondition(icon: "🦴", category: "관절 통증"),
        HealthCondition(icon: "💪🏻", category: "근육 통증"),
        HealthCondition(icon: "⚖️", category: "과체중/저체중"),
        HealthCondition(icon: "🤯", category: "스트레스"),
        HealthCondition(icon: "😢", category: "우울함/불안감"),
        HealthCondition(icon: "😵‍💫", category: "번아웃"),
        HealthCondition(icon: "🍜", category: "과식/불규칙한 식사"),
        HealthCondition(icon: "💤", category: "수면 문제"),
        HealthCondition(icon: "🔍", category: "기타")
    ]
}
