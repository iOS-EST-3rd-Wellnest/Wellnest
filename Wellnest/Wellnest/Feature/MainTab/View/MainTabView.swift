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
    
    @EnvironmentObject private var hiddenTabBar: TabBarState
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .plan:
                    PlanView()
                case .analysis:
                    AnalyticsView()
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
                    .offset(y: hiddenTabBar.isHidden ? 120 : 0)
                    .opacity(hiddenTabBar.isHidden ? 0 : 1)
                    .allowsHitTesting(!hiddenTabBar.isHidden)
                    .animation(.easeInOut(duration: 0.15), value: hiddenTabBar.isHidden)
            }
            .zIndex(1)
            
            if showScheduleMenu {
                Color.black.opacity(0.3)
                    .ignoresSafeArea(.all)
                    .zIndex(0)
                    .onTapGesture {
                        showScheduleMenu = false
                    }
            }
        }
        .fullScreenCover(item: $selectedCreationType) { type in
            switch type {
            case .createByAI:
                AIScheduleInputView(
                    selectedTab: $selectedTab,
                    selectedCreationType: $selectedCreationType
                )
            case .createByUser:
                ManualScheduleInputView(
                    selectedTab: $selectedTab,
                    selectedCreationType: $selectedCreationType
                )
            }
        }
        .onChange(of: selectedCreationType) { _ in
            showScheduleMenu = false
            
        }
        .onChange(of: selectedTab) { _ in
            showScheduleMenu = false
        }
        .padding(.bottom, 24)
        .ignoresSafeArea(edges: .bottom)
//        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
}

#Preview {
    MainTabView()
}
