//
//  MainTabView.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

//
//  MainTabView.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

import SwiftUI
import CoreData

struct MainTabView: View {
    @Environment(\.colorScheme) var colorScheme

    @StateObject private var planVM = PlanViewModel()
    
    @StateObject private var scheduleProgressViewModel: ScheduleProgressViewModel = ScheduleProgressViewModel()

    @State private var selectedTab: TabBarItem = .home
    @State private var showScheduleMenu: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var selectedCreationType: ScheduleCreationType? = nil
    @EnvironmentObject private var hiddenTabBar: TabBarState
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .plan:
                    PlanView(
                        planVM: planVM,
                        showDatePicker: $showDatePicker,
                        selectedTab: $selectedTab,
                        selectedCreationType: $selectedCreationType
                    )
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
                
                if hiddenTabBar.isHidden == false {
                    CustomTabBar(selectedTab: $selectedTab, showScheduleMenu: $showScheduleMenu)
                        .if(!showScheduleMenu && !showDatePicker) { view in
                            view.tabBarGlassBackground()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .zIndex(1)
            .animation(.spring(duration: 0.22), value: hiddenTabBar.isHidden)

            if showScheduleMenu {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(.all)
                    .zIndex(0)
                    .onTapGesture {
                        showScheduleMenu = false
                    }
            }
        }
        .dynamicTypeSize(.medium ... .xxLarge)
        .fullScreenCover(item: $selectedCreationType) { type in
            switch type {
            case .createByAI:
                AIScheduleInputView(
                    selectedTab: $selectedTab,
                    selectedCreationType: $selectedCreationType
                )
            case .createByUser:
                ManualScheduleInputView(
                    mode: .create,
                    selectedTab: $selectedTab,
                    selectedCreationType: $selectedCreationType,
                    planVM: planVM
                )
            }
        }
        .onChange(of: selectedCreationType) { _ in
            showScheduleMenu = false
        }
        .onChange(of: selectedTab) { _ in
            showScheduleMenu = false
        }
        .environmentObject(scheduleProgressViewModel)
        .padding(.bottom, 0)
//        .ignoresSafeArea(edges: .bottom)
//        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    MainTabView()
        .environmentObject(TabBarState())
}
