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

    @State private var conditions = HealthCondition.conditions

    var isButtonDisabled: Bool {
        !conditions.contains(where: { $0.isSelected })
    }

    var body: some View {
        ScrollView {
            OnboardingTitle(title: "현재 건강 상태", description: "현재 건강 상태에 해당하는 특별한 이슈가 있나요?", currentPage: currentPage, onBack: { withAnimation { currentPage -= 1 } })

            OnboardingCardContent(items: $conditions)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            FilledButton(title: "다음") {
                withAnimation {
                    currentPage += 1
                }
            }
            .disabled(isButtonDisabled)
            .opacity(isButtonDisabled ? 0.5 : 1.0)
            .padding()
            .background(.white)
        }
    }
}

#Preview {
    Preview()
}

private struct Preview: View {
    @State private var currentPage = 0

    var body: some View {
        HealthConditionTabView(userDefaultsManager: UserDefaultsManager.shared, currentPage: $currentPage)
    }
}
