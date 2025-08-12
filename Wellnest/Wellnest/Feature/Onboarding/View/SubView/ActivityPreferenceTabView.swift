//
//  ActivityPreferenceTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/5/25.
//

import SwiftUI

struct ActivityPreferenceTabView: View {
    var userEntity: UserEntity
    var viewModel: UserInfoViewModel
    
    @Binding var currentPage: Int
    @Binding var title: String

    @State private var activities = ActivityPreference.activities

    var isButtonDisabled: Bool {
        !activities.contains(where: { $0.isSelected })
    }

    var body: some View {
        ScrollView {
            OnboardingTitleDescription(description: "평소에 선호하는 운동이나 활동을 골라주세요.")
            OnboardingCardContent(items: $activities)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            FilledButton(title: "다음") {
                saveActivityPreference()
                withAnimation {
                    currentPage += 1
                }
            }
            .disabled(isButtonDisabled)
            .opacity(isButtonDisabled ? 0.5 : 1.0)
            .padding()
//            .background(.white) // TODO: 방법 1) 하얀색 배경
            .background(.ultraThinMaterial) // TODO: 방법 2) 블러 배경
                                            // TODO: 방법 3) 배경 없음(투명)
        }
        .onAppear {
            title = "선호 활동"
        }
    }
}

extension ActivityPreferenceTabView {
    private func saveActivityPreference() {
        let selectedActivities = activities.filter { $0.isSelected }

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
