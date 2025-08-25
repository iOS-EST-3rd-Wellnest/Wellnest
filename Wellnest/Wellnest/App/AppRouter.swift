//
//  AppRouter.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

import SwiftUI

struct AppRouter: View {
    @StateObject private var userDefaultsManager = UserDefaultsManager.shared
    @StateObject private var ui = AppUIState()

    var body: some View {
//        if userDefaultsManager.hasCompletedOnboarding {
            MainTabView()
                .task {
                    await WeatherCenter.shared.preloadIfNeeded()
                }
                .environmentObject(ui)
//        } else {
//            OnboardingTabView(userDefaultsManager: userDefaultsManager)
//        }
    }
}
