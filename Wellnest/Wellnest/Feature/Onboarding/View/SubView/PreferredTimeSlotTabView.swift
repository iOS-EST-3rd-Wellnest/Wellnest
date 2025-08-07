//
//  PreferredTimeSlotTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/5/25.
//

import SwiftUI

struct PreferredTimeSlotTabView: View {
    @Binding var currentPage: Int

    @State private var timeSlots = PreferredTimeSlot.timeSlots

    var isButtonDisabled: Bool {
        !timeSlots.contains(where: { $0.isSelected })
    }

    var body: some View {
        ScrollView {
            OnboardingTitle(title: "활동 시간대", description: "앞에서 선택하신 활동은 주로 언제 하시나요?", currentPage: currentPage, onBack: { withAnimation { currentPage -= 1 } })

            OnboardingCardContent(items: $timeSlots)
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
        PreferredTimeSlotTabView(currentPage: $currentPage)
    }
}
