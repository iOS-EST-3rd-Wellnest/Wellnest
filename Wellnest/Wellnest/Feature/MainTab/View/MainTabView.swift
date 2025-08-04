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
    @State private var selectedCreationType: ScheduleCreationType? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .plan:
                    PlanView()
                case .analysis:
                    PlanView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack {
                if showScheduleMenu {
                    ScheduleFloatingMenu(selectedType: $selectedCreationType, showScheduleMenu: $showScheduleMenu)
                        .padding(.bottom, Spacing.layout * 2)
                }

                CustomTabBar(selectedTab: $selectedTab, showScheduleMenu: $showScheduleMenu)
            }

        }
        .fullScreenCover(item: $selectedCreationType) { type in
            switch type {
            case .createByAI:
                AIScheduleCreationView(
                    selectedTab: $selectedTab,
                    selectedCreationType: $selectedCreationType
                )
            case .createByUser:
                ManualScheduleCreationView(
                    selectedTab: $selectedTab,
                    selectedCreationType: $selectedCreationType
                )
            }
        }
        .onChange(of: selectedCreationType) { _ in
                showScheduleMenu = false
        }
        .onChange(of: selectedTab) { _ in
            withAnimation {
                showScheduleMenu = false
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

}

#Preview {
    MainTabView()
}
