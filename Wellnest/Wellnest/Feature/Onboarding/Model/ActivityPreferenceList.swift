//
//  ActivityPreferenceList.swift
//  Wellnest
//
//  Created by 정소이 on 8/6/25.
//

import Foundation
import SwiftUI

struct ActivityPreference: SelectableItem {
    let id = UUID()
    let icon: String
    let category: String
    var isSelected: Bool = false
//    let randomCardColor: Color

    // 카드 선택 시, 컬러 에셋에 들어있는 카드 컬러를 랜덤하게 표시
//    static let availableCardColors: [Color] = [
//        Color("AccentCardBlueColor"),
//        Color("AccentCardGreenColor"),
//        Color("AccentCardPinkColor"),
//        Color("AccentCardYellowColor")
//    ]

//    init(icon: String?, category: String) {
//        self.icon = icon
//        self.category = category
//        self.randomCardColor = ActivityPreference.availableCardColors.randomElement()!
//    }

    // TODO: 사용자 정보에서 성별 선택에 따라 아이콘을 성별에 맞게 바꿔보기
    static let activities: [ActivityPreference] = [
        ActivityPreference(icon: "🚶🏽‍♂", category: "걷기/산책"),
        ActivityPreference(icon: "🏃🏾‍♂️", category: "달리기"),
        ActivityPreference(icon: "⚽️", category: "축구/풋살"),
        ActivityPreference(icon: "🚴🏾‍♂️", category: "자전거"),
        ActivityPreference(icon: "⛰️", category: "등산"),
        ActivityPreference(icon: "🏌🏾‍♂️", category: "골프"),
        ActivityPreference(icon: "🏊🏽‍♂️", category: "수영"),
        ActivityPreference(icon: "🏸", category: "배드민턴/테니스"),
        ActivityPreference(icon: "🏋🏾‍♂️", category: "헬스"),
        ActivityPreference(icon: "💪🏻", category: "홈트레이닝"),
        ActivityPreference(icon: "🩰", category: "요가/필라테스/발레"),
        ActivityPreference(icon: "💃🏽", category: "댄스 스포츠"),
        ActivityPreference(icon: "🧘🏾", category: "명상"),
        ActivityPreference(icon: "❔", category: "기타"),
        ActivityPreference(icon: "💬", category: "특별히 없음")
    ]
}

protocol SelectableItem: Identifiable, Equatable {
    var icon: String { get }
    var category: String { get }
    var isSelected: Bool { get set }
}
