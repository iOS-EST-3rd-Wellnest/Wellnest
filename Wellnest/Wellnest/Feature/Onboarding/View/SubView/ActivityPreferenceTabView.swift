//
//  ActivityPreferenceTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/5/25.
//

import SwiftUI

struct ActivityPreferenceTabView: View {
    var userEntity: UserEntity

    @ObservedObject var viewModel: UserInfoViewModel

    @Binding var currentPage: Int
    @Binding var title: String

//    @State private var activities = ActivityPreference.activities

    var isButtonDisabled: Bool {
        !viewModel.activityPreferences.contains(where: { $0.isSelected })
    }

    var body: some View {
        ScrollView {
            OnboardingTitleDescription(description: "평소에 선호하는 운동이나 활동을 골라주세요.")
            OnboardingCardContent(items: $viewModel.activityPreferences)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            OnboardingButton(title: "다음", isDisabled: isButtonDisabled) {
                saveActivityPreference()
                withAnimation { currentPage += 1 }
            }
        }
        .onAppear {
            title = "선호 활동"
        }
    }
}

extension ActivityPreferenceTabView {
    private func saveActivityPreference() {
        let selectedActivities = viewModel.activityPreferences.filter { $0.isSelected }

        if selectedActivities.contains(where: { $0.title == "특별히 없음" }) {
            userEntity.activityPreferences = nil
        } else {
            let activities = selectedActivities.map { $0.title }.joined(separator: ", ")
            userEntity.activityPreferences = activities
        }

        print(userEntity)
        try? CoreDataService.shared.saveContext()
    }
}

#Preview {
    Preview()
}

private struct Preview: View {
    @StateObject private var userInfoVM = UserInfoViewModel()
    @State private var currentPage = 0
    @State private var title = ""

    var body: some View {
        if let userEntity = userInfoVM.userEntity {
            ActivityPreferenceTabView(
                userEntity: userEntity,
                viewModel: userInfoVM,
                currentPage: $currentPage,
                title: $title
            )
        } else {
            ProgressView("Loading...")
        }
    }
}
