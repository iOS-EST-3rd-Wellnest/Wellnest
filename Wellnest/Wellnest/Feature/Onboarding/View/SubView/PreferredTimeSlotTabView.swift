//
//  PreferredTimeSlotTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/5/25.
//

import SwiftUI

struct PreferredTimeSlotTabView: View {
    var userEntity: UserEntity

    @ObservedObject var viewModel: UserInfoViewModel

    @Binding var currentPage: Int
    @Binding var title: String

//    @State private var timeSlots = PreferredTimeSlot.timeSlots

    var isButtonDisabled: Bool {
        !viewModel.preferredTimeSlots.contains(where: { $0.isSelected })
    }

    var body: some View {
        ScrollView {
            OnboardingTitleDescription(description: "앞에서 선택하신 활동은 주로 언제 하시나요?")
            OnboardingCardContent(items: $viewModel.preferredTimeSlots)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            OnboardingButton(title: "다음", isDisabled: isButtonDisabled) {
                savePreferredTimeSlot()
                withAnimation { currentPage += 1 }
            }
        }
        .onAppear {
            title = "활동 시간대"
//            ToggleCardHelper.restoreSelectedCards(items: &timeSlots, savedGoalString: userEntity.preferredTimeSlot, hasCompletedOnboarding: UserDefaultsManager.shared.hasCompletedOnboarding)
        }
    }
}

extension PreferredTimeSlotTabView {
    private func savePreferredTimeSlot() {
        let selectedTimeSlots = viewModel.preferredTimeSlots.filter { $0.isSelected }

        if selectedTimeSlots.contains(where: { $0.title == "특별히 없음" }) {
            userEntity.preferredTimeSlot = nil
        } else {
            let timeSlots = selectedTimeSlots.map { $0.title }.joined(separator: ", ")
            userEntity.preferredTimeSlot = timeSlots
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
            PreferredTimeSlotTabView(
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
