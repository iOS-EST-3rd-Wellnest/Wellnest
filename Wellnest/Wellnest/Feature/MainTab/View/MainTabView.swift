//
//  MainTabView.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: TabBarItem = .home
    @State private var showScheduleMenu: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    PlanView()
                case .plan:
                    PlanView()
                case .analysis:
                    PlanView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(selectedTab: $selectedTab, showScheduleMenu: $showScheduleMenu)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $showScheduleMenu) {
            ManualScheduleInputView(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    MainTabView()
}
