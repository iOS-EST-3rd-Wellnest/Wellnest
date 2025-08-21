//
//  HomeView.swift
//  Wellnest
//
//  Created by JuYong Lee on 7/31/25.
//

import SwiftUI
import SkeletonUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var manualScheduleVM = ManualScheduleVMFactory.make()
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var swipe = SwipeCoordinator()
    
    @State private var swipedScheduleId: UUID? = nil
    @State private var swipedDirection: SwipeDirection? = nil
    
    private let dummyData = DataLoader.loadScheduleItems()
    
    var today: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "M월 d일"

        return df.string(from: Date.now)
    }
    
    /// 오늘 일정 목록에서 미완료 일정만 필터링
    private var isCompleteSchedules: [ScheduleItem] {
//        let now = Date()
//        let cal = Calendar.current
//        
//        return dummyData
//            .filter { item in
//                !item.isCompleted && cal.isDate(item.startDate, inSameDayAs: now)
//            }
//            .sorted { $0.startDate < $1.startDate }
        
        manualScheduleVM.todaySchedules.filter { !$0.isCompleted }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.layout) {
                HStack(spacing: Spacing.layout) {
                    Image("img_profile")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)

                    VStack(alignment: .leading, spacing: Spacing.content) {
                        Text(homeVM.userInfo?.nickname ?? "")
                            .font(.title3)
                            .bold()

                        HStack {
                            ForEach(homeVM.hashtagList, id: \.self) {
                                Text("\($0)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.bottom, Spacing.layout)

                HStack {
                    Text(today)
                        .font(.title2)
                        .bold()
                    
                    Spacer()
                }

                HStack(spacing: Spacing.layout) {
                    if homeVM.goalList.isEmpty {
                        SkeletonView()
                    } else {
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .fill(colorScheme == .dark ? Color(.gray) : .white)
                            .frame(minHeight: 180)
                            .defaultShadow()
                            .overlay(alignment: .topLeading) {
                                VStack(alignment: .leading, spacing: Spacing.content) {
                                    Text("목표")
                                        .font(.title3)
                                        .bold()
                                        .padding(.vertical, Spacing.content)
                                    
                                    ForEach(homeVM.goalList, id: \.self) {
                                        Text("\($0)")
                                            .font(.footnote)
                                    }
                                }
                                .padding()
                            }
                        
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .fill(colorScheme == .dark ? Color(.gray) : .white)
                            .frame(minHeight: 180)
                            .defaultShadow()
                            .overlay {
                                
                            }
                    }
                }
                
                HStack {
                    VStack(spacing: 0) {
                        if isCompleteSchedules.isEmpty {
                            Text("일정을 추가 해주세요.")
                                .padding(.vertical, 40)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.large)
                                        .fill(colorScheme == .dark ? Color(.gray) : .white)
                                        .frame(height: 100)
                                        .defaultShadow()
                                )
                        } else {
                            ForEach(isCompleteSchedules) { schedule in
                                ScheduleCardView(manualScheduleVM: manualScheduleVM, schedule: schedule)
                                    .environmentObject(swipe)
                                    .padding(.vertical, Spacing.content)
                            }
                        }
                    }
                    .task {
                        manualScheduleVM.loadTodaySchedules()
                    }

                }
                .padding(.bottom, Spacing.layout * 2)
            }
            .padding(.horizontal)
    
            RecommendView(homeVM: homeVM)
                .padding(.bottom, 100)
        }
        .task {
            await homeVM.fetchDailySummary()
            await homeVM.refreshWeatherContent()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(ManualScheduleVMFactory.make())
}

private struct SkeletonView: View {
    var body: some View {
        HStack {
            Rectangle()
                .skeleton(with: true, shape: .rounded(.radius(CornerRadius.medium, style: .continuous)))
                .frame(minHeight: 180)
            
            Rectangle()
                .skeleton(with: true, shape: .rounded(.radius(CornerRadius.medium, style: .continuous)))
                .frame(minHeight: 180)
        }
    }
}
