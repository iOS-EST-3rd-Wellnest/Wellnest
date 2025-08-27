//
//  TabBarItem.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

import Foundation

enum TabBarItem: Hashable, CaseIterable {
    case home, plan, analysis, settings

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .plan: return "calendar"
        case .analysis: return "chart.bar.xaxis"
        case .settings: return "gearshape.fill"
        }
    }

    var title: String {
        switch self {
        case .home: return "홈"
        case .plan: return "일정"
        case .analysis: return "분석"
        case .settings: return "설정"
        }
    }
}
