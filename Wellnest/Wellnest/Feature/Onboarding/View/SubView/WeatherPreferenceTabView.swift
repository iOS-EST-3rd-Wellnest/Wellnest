//
//  WeatherPreferenceTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/5/25.
//

import SwiftUI

struct WeatherPreferenceTabView: View {
    var userEntity: UserEntity
    var viewModel: UserInfoViewModel
    
    @Binding var currentPage: Int
    @Binding var title: String

    @State private var weathers = WeatherPreference.weathers

    var isButtonDisabled: Bool {
        !weathers.contains(where: { $0.isSelected })
    }

    var body: some View {
        ScrollView {
            OnboardingTitleDescription(description: "평소에 어떤 날씨를 좋아하시나요?")
            OnboardingCardContent(items: $weathers)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            FilledButton(title: "다음") {
                saveWeatherPreference()
                withAnimation {
                    currentPage += 1
                }
            }
            .disabled(isButtonDisabled)
            .opacity(isButtonDisabled ? 0.5 : 1.0)
            .padding()
            .background(.white)
        }
        .onAppear {
            title = "선호 날씨"
        }
    }
}

extension WeatherPreferenceTabView {
    private func saveWeatherPreference() {
        let selectedWeathers = weathers.filter { $0.isSelected }

        if selectedWeathers.contains(where: { $0.title == "특별히 없음" }) {
            userEntity.weatherPreferences = nil
        } else {
            let weathers = selectedWeathers.map { $0.title }.joined(separator: ", ")
            userEntity.weatherPreferences = weathers
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
            WeatherPreferenceTabView(
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
