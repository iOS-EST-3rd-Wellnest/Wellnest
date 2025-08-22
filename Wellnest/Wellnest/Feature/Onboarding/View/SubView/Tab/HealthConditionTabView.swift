//
//  HealthConditionTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/6/25.
//

import SwiftUI

struct HealthConditionTabView: View {
    var userEntity: UserEntity

    @ObservedObject var viewModel: UserInfoViewModel
    @ObservedObject var userDefaultsManager: UserDefaultsManager
    
    @Binding var currentPage: Int
    @Binding var title: String

    var isInSettings: Bool = false

    var isButtonDisabled: Bool {
        !viewModel.healthConditions.contains(where: { $0.isSelected })
    }

    var body: some View {
        ScrollView {
            OnboardingTitleDescription(description: "현재 건강 상태에 해당하는 특별한 이슈가 있나요?")
            OnboardingCardContent(items: $viewModel.healthConditions)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            OnboardingButton(
                title: "완료",
                isDisabled: isButtonDisabled,
                action: {
                    saveHealthCondition()
                    if !isInSettings {
                        withAnimation { userDefaultsManager.hasCompletedOnboarding = true }
                    }
                },
                currentPage: $currentPage,
                showPrevious: isInSettings,
                isLastStep: isInSettings
            )
        }
        .onAppear {
            title = "현재 건강 상태"
        }
    }
}

extension HealthConditionTabView {
    private func saveHealthCondition() {
        let selectedConditions = viewModel.healthConditions.filter { $0.isSelected }

        if selectedConditions.contains(where: { $0.title == "특별히 없음" }) {
            userEntity.healthConditions = nil
        } else {
            let conditions = selectedConditions.map { $0.title }.joined(separator: ", ")
            userEntity.healthConditions = conditions
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
            HealthConditionTabView(
                userEntity: userEntity,
                viewModel: userInfoVM,
                userDefaultsManager: UserDefaultsManager.shared,
                currentPage: $currentPage,
                title: $title
            )
        } else {
            ProgressView("Loading...")
        }
    }
}
