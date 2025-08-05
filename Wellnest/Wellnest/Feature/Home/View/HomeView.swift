//
//  HomeView.swift
//  Wellnest
//
//  Created by JuYong Lee on 7/31/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: ManualScheduleViewModel
    
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
            VStack(alignment: .leading) {
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

                Text(today)
                    .font(.title2)
                    .bold()
                    .padding(.horizontal, Spacing.content)

                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .fill(.white)
                        .frame(minWidth: 170, minHeight: 200)
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
                            .frame(minWidth: 170)
                            .foregroundStyle(.accentButton)

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
                        if viewModel.todaySchedules.isEmpty {
                        Text("일정을 추가 해주세요.")
                            .padding(.vertical, 25)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.large)
                                    .fill(.white)
                                    .frame(width: UIScreen.main.bounds.width - 46, height: 90)
                                    .defaultShadow()
                            )
                        } else {
                            ForEach(viewModel.todaySchedules) { schedule in
                                ScheduleCardView(
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
                        viewModel.loadTodaySchedules()
                    }
                    
                    Spacer()
                }
                
                Text("오늘의 한마디")
                    .font(.title2)
                    .bold()
                    .padding(Spacing.content)

                Text("날씨")
                    .font(.title2)
                    .bold()
                    .padding(Spacing.content)

                Text("추천 식단")
                    .font(.title2)
                    .bold()
                    .padding(Spacing.content)

                Text("추천 영상")
                    .font(.title2)
                    .bold()
                    .padding(Spacing.content)

                Text("추천 글")
                    .font(.title2)
                    .bold()
                    .padding(Spacing.content)
            }
            .padding()
            .padding(.bottom, 80)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(ManualScheduleViewModel())
}
