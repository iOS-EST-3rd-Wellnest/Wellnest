//
//  WeatherPreferenceTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/5/25.
//

import SwiftUI

struct WeatherPreferenceTabView: View {
    @Binding var currentPage: Int

    @State private var weathers = WeatherPreference.weathers

    var isButtonDisabled: Bool {
        !weathers.contains(where: { $0.isSelected })
    }

    var body: some View {
        ScrollView {
            OnboardingTitle(title: "선호 날씨", description: "평소에 어떤 날씨를 좋아하시나요?", currentPage: currentPage, onBack: { withAnimation { currentPage -= 1 } })

            OnboardingCardContent(items: $weathers)
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
        WeatherPreferenceTabView(currentPage: $currentPage)
    }
}
