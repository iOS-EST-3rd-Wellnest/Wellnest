//
//  AppRouter.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

import SwiftUI

struct AppRouter: View {
    @StateObject private var userDefaultsManager = UserDefaultsManager.shared

    var body: some View {
        if userDefaultsManager.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingTabView(userDefaultsManager: userDefaultsManager)
        }
    }
}
