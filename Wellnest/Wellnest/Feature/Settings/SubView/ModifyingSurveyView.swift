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
                case 0:
                    WellnessGoalTabView(userEntity: user, viewModel: viewModel, currentPage: $currentPage, title: $title)
                case 1:
                    ActivityPreferenceTabView(userEntity: user, viewModel: viewModel, currentPage: $currentPage, title: $title, isInSettings: true)
                case 2:
                    PreferredTimeSlotTabView(userEntity: user, viewModel: viewModel, currentPage: $currentPage, title: $title, isInSettings: true)
                case 3:
                    WeatherPreferenceTabView(userEntity: user, viewModel: viewModel, currentPage: $currentPage, title: $title, isInSettings: true)
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
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    withAnimation { dismiss() }
                } label: {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.gray)
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
