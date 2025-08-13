//
//  WeatherPreferenceTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/5/25.
//

import SwiftUI

struct WeatherPreferenceTabView: View {
    var userEntity: UserEntity

    @ObservedObject var viewModel: UserInfoViewModel

    @Binding var currentPage: Int
    @Binding var title: String

//    @State private var weathers = WeatherPreference.weathers

    var isButtonDisabled: Bool {
        !viewModel.weatherPreferences.contains(where: { $0.isSelected })
    }

    var body: some View {
        ScrollView {
            OnboardingTitleDescription(description: "평소에 어떤 날씨를 좋아하시나요?")
            OnboardingCardContent(items: $viewModel.weatherPreferences)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            OnboardingButton(title: "다음", isDisabled: isButtonDisabled) {
                saveWeatherPreference()
                withAnimation { currentPage += 1 }
            }
        }
        .onAppear {
            title = "선호 날씨"
//            ToggleCardHelper.restoreSelectedCards(items: &weathers, savedGoalString: userEntity.weatherPreferences, hasCompletedOnboarding: UserDefaultsManager.shared.hasCompletedOnboarding)
        }
    }
}

extension WeatherPreferenceTabView {
    private func saveWeatherPreference() {
        let selectedWeathers = viewModel.weatherPreferences.filter { $0.isSelected }

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
