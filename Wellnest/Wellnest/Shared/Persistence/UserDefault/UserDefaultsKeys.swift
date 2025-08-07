//
//  UserDefaultsKeys.swift
//  Wellnest
//
//  Created by 정소이 on 8/5/25.
//

import Foundation

enum UserDefaultsKeys {
    /// 온보딩 화면 관련 키
    enum Onboarding {
        static let isOnboarding = "isOnboarding"
    }

    /// 설정 화면 관련 키
    enum Settings {
        static let notificationEnabled = "notificationEnabled"
        static let isHealthDataEnabled = "isHealthDataEnabled"
        // 설정 관련 키를 여기에 추가해주세요.
    }

    // 기타 키 추가 시 다음과 같이 추가해주세요.
    // enum Profile { ... }
}
