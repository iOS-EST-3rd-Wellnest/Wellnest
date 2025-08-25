//
//  ModifyingSurveyView.swift
//  Wellnest
//
//  Created by 전광호 on 8/1/25.
//

import SwiftUI

struct ModifyingSurveyView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = UserInfoViewModel()

    @State private var currentPage: Int = 0
    @State private var title: String = ""

    var body: some View {
        VStack {
            if let user = viewModel.userEntity {
                switch currentPage {
                /// 윌니스 목표
                case 0:
                    WellnessGoalTabView(userEntity: user, viewModel: viewModel, currentPage: $currentPage, title: $title)
                /// 선호 활동
                case 1:
                    ActivityPreferenceTabView(userEntity: user, viewModel: viewModel, currentPage: $currentPage, title: $title, isInSettings: true)
                /// 선호 시간
                case 2:
                    PreferredTimeSlotTabView(userEntity: user, viewModel: viewModel, currentPage: $currentPage, title: $title, isInSettings: true)
                /// 선호 날씨
                case 3:
                    WeatherPreferenceTabView(userEntity: user, viewModel: viewModel, currentPage: $currentPage, title: $title, isInSettings: true)
                /// 건강 상태
                case 4:
                    HealthConditionTabView(userEntity: user, viewModel: viewModel, userDefaultsManager: UserDefaultsManager.shared, currentPage: $currentPage, title: $title, isInSettings: true)
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation { dismiss() }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.wellnestOrange)
                }
            }
        }
        .onAppear {
            viewModel.screenContext = .settings
            viewModel.loadActivities()
            viewModel.loadWellnessGoals()
            viewModel.loadPreferredTimeSlots()
            viewModel.loadWeatherPreferences()
            viewModel.loadHealthConditions()
        }
    }
}

#Preview {
    ModifyingSurveyView()
}
