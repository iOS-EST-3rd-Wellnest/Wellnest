//
//  HomeView.swift
//  Wellnest
//
//  Created by JuYong Lee on 7/31/25.
//

import SwiftUI
import CoreData

struct HomeView: View {
    @State var name: String = "홍길동"

    @EnvironmentObject private var viewModel: ScheduleViewModel

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
                
            }
            .padding()
#warning("⛔️ FixMe: 테스트용. 주용님이 ScheduleRowView UI 수정해주세요.")
    #if DEBUG
            VStack(alignment: .leading, spacing: Spacing.content) {
                if viewModel.todaySchedules.isEmpty {
                    Text("오늘 일정이 없습니다.")
                        .foregroundStyle(.secondary)
                        .padding(.top, Spacing.inline)
                } else {
                    ForEach(viewModel.todaySchedules) { schedule in
                        ScheduleRowView(schedule: schedule)
                            .padding(.vertical, Spacing.inline)
                    }
                }
            }
            .padding(.horizontal)
            .onAppear {
                viewModel.loadTodaySchedules()
            }
    #endif
        }
    }
}

#Preview {
    HomeView()
}

