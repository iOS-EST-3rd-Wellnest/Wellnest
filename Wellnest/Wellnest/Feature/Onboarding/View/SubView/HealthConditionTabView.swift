//
//  HealthConditionTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/6/25.
//

import SwiftUI

struct HealthConditionTabView: View {
    @ObservedObject var userDefaultsManager: UserDefaultsManager
    
    @Binding var currentPage: Int
    @Binding var title: String

    @State private var conditions = HealthCondition.conditions

    var isButtonDisabled: Bool {
        !conditions.contains(where: { $0.isSelected })
    }

    var body: some View {
        ScrollView {
            OnboardingTitleDescription(description: "현재 건강 상태에 해당하는 특별한 이슈가 있나요?")

            OnboardingCardContent(items: $conditions)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            FilledButton(title: "완료") {
                withAnimation {
                    userDefaultsManager.isOnboarding = true
                }
            }
            .disabled(isButtonDisabled)
            .opacity(isButtonDisabled ? 0.5 : 1.0)
            .padding()
            .background(.white)
        }
        .onAppear {
            title = "현재 건강 상태"
        }
    }
}

#Preview {
    Preview()
}

private struct Preview: View {
    @State private var currentPage = 0
    @State private var title = ""

    var body: some View {
        HealthConditionTabView(userDefaultsManager: UserDefaultsManager.shared, currentPage: $currentPage, title: $title)
    }
}
