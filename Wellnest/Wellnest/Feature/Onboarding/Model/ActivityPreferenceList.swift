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

    static func activities(for gender: String) -> [ActivityPreference] {
        let isFemale = (gender == "여성")

        return [
            // TODO: 준일님과 얘기해 타이틀 형식 변경
            ActivityPreference(icon: isFemale ? "🚶🏽‍♀️" : "🚶🏽‍♂️", title: "걷기/산책"),
            ActivityPreference(icon: isFemale ? "🏃🏽‍♀️" : "🏃🏽‍♂️", title: "달리기"),
            ActivityPreference(icon: "⚽️", title: "축구/풋살"),
            ActivityPreference(icon: isFemale ? "🚴🏽‍♀️" : "🚴🏾‍♂️", title: "자전거"),
            ActivityPreference(icon: "⛰️", title: "등산"),
            ActivityPreference(icon: isFemale ? "🏌🏽‍♀️" : "🏌🏾‍♂️", title: "골프"),
            ActivityPreference(icon: isFemale ? "🏊🏽‍♀️" : "🏊🏽‍♂️", title: "수영"),
            ActivityPreference(icon: "🏸", title: "배드민턴/테니스"),
            ActivityPreference(icon: isFemale ? "🏋🏽‍♀️" : "🏋🏽‍♂️", title: "헬스"),
            ActivityPreference(icon: "💪🏻", title: "홈트레이닝"),
            ActivityPreference(icon: "🩰", title: "요가/필라테스/발레"),
            ActivityPreference(icon: isFemale ? "💃🏽" : "🕺🏽", title: "댄스 스포츠"),
            ActivityPreference(icon: isFemale ? "🧘🏽‍♀️" : "🧘🏽‍♂️", title: "명상"),
            ActivityPreference(icon: "❔", title: "기타"),
            ActivityPreference(icon: "💬", title: "특별히 없음")
        ]
    }
}

protocol SelectableItem: Identifiable, Equatable {
    var icon: String { get }
    var title: String { get }
    var isSelected: Bool { get set }
}
