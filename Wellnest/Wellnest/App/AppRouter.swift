//
//  AppRouter.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

import SwiftUI

struct AppRouter: View {
    // 온보딩 여부 isOnboarded 추가해주세요!
    @AppStorage("isOnboarded") private var isOnboarded: Bool = true
   

    var body: some View {
        if isOnboarded {
            MainTabView()
        } else {
            // OnboardingView()
        }
    }
}
