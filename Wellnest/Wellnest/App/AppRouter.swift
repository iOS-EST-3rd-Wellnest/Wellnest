//
//  AppRouter.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

import SwiftUI

struct AppRouter: View {
    @StateObject private var userDefaultsManager = UserDefaultsManager.shared
    @StateObject private var hiddenTabBar = TabBarState()
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
            } else {
                if userDefaultsManager.hasCompletedOnboarding {
                    MainTabView()
                        .task {
                            await WeatherCenter.shared.preloadIfNeeded()
                        }
                        .environmentObject(hiddenTabBar)
                } else {
                    OnboardingTabView(userDefaultsManager: userDefaultsManager)
                }
            }
        }
    }
}
