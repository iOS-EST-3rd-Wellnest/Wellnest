//
//  HomeView.swift
//  Wellnest
//
//  Created by JuYong Lee on 7/31/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    
//    @StateObject private var manualScheduleVM = ManualScheduleViewModel()
    @StateObject private var manualScheduleVM = ManualScheduleVMFactory.make()
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var planVM = PlanViewModel()
    
    @State var name: String = "홍길동"
    
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
//    private var isCompleteSchedules: [ScheduleItem] {
////        let now = Date()
////        let cal = Calendar.current
////        
////        return dummyData
////            .filter { item in
////                !item.isCompleted && cal.isDate(item.startDate, inSameDayAs: now)
////            }
////            .sorted { $0.startDate < $1.startDate }
//        
//        manualScheduleVM.todaySchedules.filter { !$0.isCompleted }
//    }
    
    private var isCompleteSchedules: [ScheduleItem] {
        planVM.mergedItems.filter { !$0.isCompleted }
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
                        Text(name)
                            .font(.title3)
                            .bold()

                        Text("#20대 #아침형 #식단관리")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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

                                Text("1,000kcal 태우기")
                                    .font(.footnote)
                                
                                Text("10,000보 걷기")
                                    .font(.footnote)
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
                
                HStack {
                    VStack {
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
                                ScheduleCardView(
                                    manualScheduleVM: manualScheduleVM,
                                    planVM: planVM,
                                    schedule: schedule,
                                    swipedScheduleId: swipedScheduleId,
                                    swipedDirection: swipedDirection) { id, direction in
                                        withAnimation {
                                            swipedScheduleId = id
                                            swipedDirection = direction
                                        }
                                    }
                                    .padding(.vertical, Spacing.content)
                            }
                        }
                    }
//                    .onAppear {
//                        manualScheduleVM.loadTodaySchedules()
//                    }
                    .task {
                        manualScheduleVM.loadTodaySchedules()
                    }

                }
                .padding(.bottom, Spacing.layout * 2)
                .onAppear {
                    planVM.preloadCurrentAndNeighbors()
                    Task {
                        await planVM.refreshHomeTodayWithFallback()
                    }
                    planVM.startObservingCalendarForHome()
                }
            }
            .padding(.horizontal)
    
            RecommendView(homeVM: homeVM)
                .padding(.bottom, 100)
        }
        .onAppear {
            //homeVM.quoteOfTheDayRequest()
            //homeVM.weatherRequest()
            //homeVM.videoRequest()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(ManualScheduleVMFactory.make())
}
