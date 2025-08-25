//
//  HomeView.swift
//  Wellnest
//
//  Created by JuYong Lee on 7/31/25.
//

import SwiftUI

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var manualScheduleVM = ManualScheduleVMFactory.make()
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var swipe = SwipeCoordinator()
    
    @State private var profileVstackHeight: CGFloat = .zero
    @State private var offsetY: CGFloat = .zero
    
    var today: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "M월 d일"
        
        return df.string(from: Date.now)
    }
    
    private var imgHeight: CGFloat {
        return max(50, profileVstackHeight)
    }
    
    /// 오늘 일정 목록에서 미완료 일정만 필터링
    private var isCompleteSchedules: [ScheduleItem] {
        manualScheduleVM.todaySchedules.filter { !$0.isCompleted }
    }
    
    private var scrollOffsetView: some View {
        GeometryReader { proxy in
            let offsetY = proxy.frame(in: .global).origin.y
            Color.clear
                .preference(key: ScrollPreferenceKey.self, value: offsetY)
                .onAppear {
                    self.offsetY = offsetY
                }
        }
        .frame(height: 0)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.layout) {
                scrollOffsetView
                
                HStack(spacing: Spacing.layout) {
                    VStack(alignment: .leading, spacing: Spacing.content) {
                        Text(homeVM.userInfo?.nickname ?? "")
                            .font(.title2)
                            .bold()
                        
                        HStack {
                            ForEach(homeVM.hashtagList, id: \.self) {
                                Text("\($0)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .background(
                        GeometryReader { profileGeometry in
                            Color.clear
                                .preference(key: SizePreferenceKey.self, value: profileGeometry.size.height)
                        }
                    )
                    
                    Spacer()
                    
                    Image("img_profile")
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: imgHeight, height: imgHeight)
                        .clipShape(RoundedRectangle(cornerRadius: imgHeight / 2))
                }
                .padding(.bottom, Spacing.layout)
                .onPreferenceChange(SizePreferenceKey.self) { profileVstackHeight = $0 }
                
                HStack {
                    Text(today)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                HStack(spacing: Spacing.layout) {
                    if homeVM.goalList.isEmpty {
                        GoalSkeletonView()
                    } else {
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                            .frame(minHeight: 180)
                            .roundedBorder(cornerRadius: CornerRadius.large)
                            .defaultShadow()
                            .overlay(alignment: .topLeading) {
                                VStack(alignment: .leading, spacing: Spacing.content) {
                                    Text("목표")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .padding(.vertical, Spacing.inline)
                                    
                                    ForEach(homeVM.goalList, id: \.self) {
                                        Text("\($0)")
                                            .font(.footnote)
                                    }
                                }
                                .padding()
                            }
                        
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                            .frame(minHeight: 180)
                            .roundedBorder(cornerRadius: CornerRadius.large)
                            .defaultShadow()
                    }
                }
                
                HStack {
                    VStack(spacing: 0) {
                        if isCompleteSchedules.isEmpty {
                            RoundedRectangle(cornerRadius: CornerRadius.large)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                                .frame(height: 100)
                                .roundedBorder(cornerRadius: CornerRadius.large)
                                .defaultShadow()
                                .overlay {
                                    Text("일정을 추가 해주세요.")
                                        .frame(maxWidth: .infinity)
                                    
                                }
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
            .padding(.top, Spacing.content)
            .padding(.horizontal)
            
            RecommendView(homeVM: homeVM)
                .padding(.bottom, 100)
        }
        .background(Color(.systemBackground))
        .onPreferenceChange(ScrollPreferenceKey.self) { value in
            self.offsetY = value
        }
        .overlay(alignment: .top) {
            GeometryReader { proxy in
                Group{
                    if offsetY >= proxy.safeAreaInsets.top {
                        Rectangle()
                            .fill(Color(.systemBackground))
                    } else {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                    }
                }
                .frame(height: proxy.safeAreaInsets.top)
                .ignoresSafeArea(edges: .top)
            }
            .allowsHitTesting(false)
        }
        .task {
            await homeVM.fetchDailySummary()
            //await homeVM.refreshWeatherContent()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(ManualScheduleVMFactory.make())
}

private struct GoalSkeletonView: View {
    var body: some View {
        HStack {
            SkeletonView(shape: RoundedRectangle(cornerRadius: CornerRadius.large))
                .frame(minHeight: 180)
            
            SkeletonView(shape: RoundedRectangle(cornerRadius: CornerRadius.large))
                .frame(minHeight: 180)
        }
    }
}
