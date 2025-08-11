//
//  HealthConditionList.swift
//  Wellnest
//
//  Created by 정소이 on 8/6/25.
//

import Foundation

struct HealthCondition: SelectableItem {
    let id = UUID()
    let icon: String
    let title: String
    var isSelected: Bool = false

    static let conditions: [HealthCondition] = [
        HealthCondition(icon: "😀", title: "특별히 없음"),
        HealthCondition(icon: "🩸", title: "당뇨"),
        HealthCondition(icon: "🫀", title: "고혈압/부정맥"),
        HealthCondition(icon: "🦴", title: "관절 통증"),
        HealthCondition(icon: "💪🏻", title: "근육 통증"),
        HealthCondition(icon: "⚖️", title: "과체중/저체중"),
        HealthCondition(icon: "🤯", title: "스트레스"),
        HealthCondition(icon: "😢", title: "우울함/불안감"),
        HealthCondition(icon: "😵‍💫", title: "번아웃"),
        HealthCondition(icon: "🍜", title: "과식/불규칙한 식사"),
        HealthCondition(icon: "💤", title: "수면 문제"),
        HealthCondition(icon: "❔", title: "기타")
    ]
}
