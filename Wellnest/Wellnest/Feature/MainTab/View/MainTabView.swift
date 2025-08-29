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
    @State private var selectedCreationType: ScheduleCreationType? = nil
    @EnvironmentObject private var hiddenTabBar: TabBarState
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .plan:
                    PlanView(planVM: planVM, selectedTab: $selectedTab, selectedCreationType: $selectedCreationType)
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
                        .background {
                            ZStack {
                                Rectangle()
                                    .fill(.ultraThinMaterial)

                                Rectangle()
                                    .fill(colorScheme == .light ? .white : .black)

                            }
                            .mask {
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .clear, location: 0.0),
                                        .init(color: .black.opacity(0.5), location: 0.3),
                                        .init(color: .black, location: 0.5),
                                        .init(color: .black, location: 0.7),
                                        .init(color: .black, location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                            .ignoresSafeArea(edges: .bottom)

                        }
//                        .background {
//                            GeometryReader { geometry in
//                                Rectangle()
//                                    .fill(.ultraThinMaterial)
//                                    .frame(height: 60 + geometry.safeAreaInsets.bottom)
//
//                                    .ignoresSafeArea(edges: .bottom)
//                            }
//                        }
                }
            }
            .zIndex(1)

            if showScheduleMenu {
                Rectangle()
                    .fill(.ultraThickMaterial)
                    .opacity(0.92)
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
