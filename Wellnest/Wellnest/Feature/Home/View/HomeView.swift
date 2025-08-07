//
//  HomeView.swift
//  Wellnest
//
//  Created by JuYong Lee on 7/31/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var manualScheduleVM = ManualScheduleViewModel()
    @StateObject private var homeVM = HomeViewModel()
    
    @State var name: String = "홍길동"
    
    @State private var swipedScheduleId: UUID? = nil
    @State private var swipedDirection: SwipeDirection? = nil
    
    var today: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "M월 d일"

        return df.string(from: Date.now)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
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
                .padding()

                HStack {
                    Text(today)
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, Spacing.content)
                    
                    Spacer()
                }

                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .fill(colorScheme == .dark ? Color(.gray) : .white)
                        .frame(minWidth: UIScreen.main.bounds.width / 2 - (Spacing.layout * 2), minHeight: 170)
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
                        .padding(.horizontal, Spacing.content)

                    ZStack {
                        Circle()
                            .padding(.horizontal, Spacing.content)
                            .frame(minWidth: UIScreen.main.bounds.width / 2 - (Spacing.layout * 2))
                            .foregroundStyle(.blue)

                        Circle()
                            .frame(maxWidth: 140)
                            .foregroundStyle(.gray)

                        VStack(spacing: 0) {
                            Group {
                                Text("Today")
                                    .font(.footnote)
                                    .bold()

                                Text("schedule")
                                    .font(.footnote)

                                Text("attainment")
                                    .font(.footnote)

                                Text("88%")
                                    .font(.title)
                                    .bold()
                                    .padding(Spacing.content)
                            }
                            .multilineTextAlignment(.center)
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    
                    VStack {
                        if manualScheduleVM.todaySchedules.isEmpty {
                            Text("일정을 추가 해주세요.")
                                .padding(.vertical, 40)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.large)
                                        .fill(colorScheme == .dark ? Color(.gray) : .white)
                                        .frame(width: UIScreen.main.bounds.width - (Spacing.layout * 3), height: 100)
                                        .defaultShadow()
                                )
                        } else {
                            ForEach(manualScheduleVM.todaySchedules) { schedule in
                                ScheduleCardView(
                                    manualScheduleVM: manualScheduleVM,
                                    schedule: schedule,
                                    swipedScheduleId: swipedScheduleId,
                                    swipedDirection: swipedDirection) { id, direction in
                                        withAnimation {
                                            swipedScheduleId = id
                                            swipedDirection = direction
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.vertical, Spacing.layout)
                    .padding(.horizontal, Spacing.inline)
                    .onAppear {
                        manualScheduleVM.loadTodaySchedules()
                    }
                    
                    Spacer()
                }
                
                RecommendView(homeVM: homeVM)
            }
            .padding()
            .padding(.bottom, 85)
        }
        .onAppear {
//            homeVM.videoRequest()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(ManualScheduleViewModel())
}
