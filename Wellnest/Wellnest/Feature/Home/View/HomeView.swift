//
//  HomeView.swift
//  Wellnest
//
//  Created by JuYong Lee on 7/31/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var manualScheduleVM = ManualScheduleVMFactory.make()
    
    @State private var offsetY: CGFloat = .zero
    
    /// 오늘 일정 목록에서 미완료 일정만 필터링
    private var isCompleteSchedules: [ScheduleItem] {
        manualScheduleVM.todaySchedules.filter { !$0.isCompleted }
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.layout) {
                SafeAreaBlurView(offsetY: $offsetY, space: .named("homeScroll"))
                
                HomeProfileView(homeVM: homeVM)
                    .padding(.bottom, Spacing.layout)
                
                TodayCardView(homeVM: homeVM, manualScheduleVM: manualScheduleVM, isCompleteSchedules: isCompleteSchedules)
                
                if UIDevice.current.userInterfaceIdiom != .pad {
                    if isCompleteSchedules.isEmpty {
                        EmptyScheduleView()
                    } else {
                        HomeScheduleView(manualScheduleVM: manualScheduleVM, isCompleteSchedules: isCompleteSchedules)
                            .padding(.bottom, Spacing.layout * 2)
                    }
                }
            }
            .padding(.horizontal)
            .task {
                manualScheduleVM.loadTodaySchedules()
            }
            
            RecommendView(homeVM: homeVM)
                .padding(.bottom, 100)
        }
        .background(Color(.systemBackground))
        .coordinateSpace(name: "homeScroll")
        .safeAreaBlur(offsetY: $offsetY)
        .task {
            await homeVM.fetchDailySummary()
            //await homeVM.refreshWeatherContent()
        }
    }
}

#Preview {
    HomeView()
}
