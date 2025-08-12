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
    let title: String
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
        ActivityPreference(icon: "🚶🏽‍♂", title: "걷기/산책"),
        ActivityPreference(icon: "🏃🏾‍♂️", title: "달리기"),
        ActivityPreference(icon: "⚽️", title: "축구/풋살"),
        ActivityPreference(icon: "🚴🏾‍♂️", title: "자전거"),
        ActivityPreference(icon: "⛰️", title: "등산"),
        ActivityPreference(icon: "🏌🏾‍♂️", title: "골프"),
        ActivityPreference(icon: "🏊🏽‍♂️", title: "수영"),
        ActivityPreference(icon: "🏸", title: "배드민턴/테니스"),
        ActivityPreference(icon: "🏋🏾‍♂️", title: "헬스"),
        ActivityPreference(icon: "💪🏻", title: "홈트레이닝"),
        ActivityPreference(icon: "🩰", title: "요가/필라테스/발레"),
        ActivityPreference(icon: "💃🏽", title: "댄스 스포츠"),
        ActivityPreference(icon: "🧘🏾", title: "명상"),
        ActivityPreference(icon: "❔", title: "기타"),
        ActivityPreference(icon: "💬", title: "특별히 없음")
    ]
}

protocol SelectableItem: Identifiable, Equatable {
    var icon: String { get }
    var title: String { get }
    var isSelected: Bool { get set }
}
