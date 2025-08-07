//
//  OnboardingTableView.swift
//  Wellnest
//
//  Created by 정소이 on 8/1/25.
//

import SwiftUI

struct OnboardingTitle: View {
    let title: String
    let description: String?
    let currentPage: Int
    let onBack: () -> Void

    var body: some View {
        HStack {
            if currentPage > 0 {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            } else {
                Image(systemName: "chevron.backward")
                    .font(.title2)
                    .opacity(0)
            }

            Spacer()

            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            // 타이틀을 가운데에 배치하기 위함
            Image(systemName: "chevron.backward")
                    .opacity(0)
                    .font(.title2)
        }
        .padding(.horizontal)
        .padding(.top)

        if let description {
            Text(description)
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.content)
                .padding(.horizontal)
                .padding(.bottom, 60)
        }
    }
}

struct OnboardingTabView: View {
//    @AppStorage("isOnboarding") var isOnboarding: Bool = false
    @ObservedObject var userDefaultsManager: UserDefaultsManager

    @State private var currentPage: Int = 0

//    init(startPage: Int = 0) {
//        _currentPage = State(initialValue: startPage)
//    }

    var body: some View {
        VStack {
            // 사용자 입력을 받지 않아도 페이징이 되는 걸 막기 위함
            switch currentPage {
            case 0:
                MotivationTabView(currentPage: $currentPage)
            case 1:
                IntroductionTabView(currentPage: $currentPage)
            case 2:
                IntroductionTabView(currentPage: $currentPage)
            case 3:
                UserInfoTabView(currentPage: $currentPage)
            case 4:
                WellnessGoalTabView(currentPage: $currentPage)
            case 5:
                ActivityPreferenceTabView(currentPage: $currentPage)
            case 6:
                PreferredTimeSlotTabView(currentPage: $currentPage)
            case 7:
                WeatherPreferenceTabView(currentPage: $currentPage)
            case 8:
                HealthConditionTabView(userDefaultsManager: UserDefaultsManager.shared, currentPage: $currentPage)
            default:
                EmptyView()
            }
//            TabView(selection: $currentPage) {
//                MotivationTabView(currentPage: $currentPage)
//                    .tag(0)
//
//                IntroductionTabView(currentPage: $currentPage)
//                    .tag(1)
//
//                IntroductionTabView(currentPage: $currentPage)
//                    .tag(2)
//
//                UserInfoTabView(currentPage: $currentPage)
//                    .tag(3)
//
//                WellnessGoalTabView(currentPage: $currentPage)
//                    .tag(4)
//
//                ActivityPreferenceTabView(currentPage: $currentPage)
//                    .tag(5)
//
//                PreferredTimeSlotTabView(currentPage: $currentPage)
//                    .tag(6)
//
//                WeatherPreferenceTabView(currentPage: $currentPage)
//                    .tag(7)
//
//                HealthConditionTabView(userDefaultsManager: UserDefaultsManager.shared, currentPage: $currentPage)
//                    .tag(8)
//            }
//            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            // Custom Indicator
//            if currentPage < totalPages {
//                HStack(spacing: 8) {
//                    ForEach(0 ..< totalPages, id: \.self) { index in
//                        Circle()
//                            .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.3))
//                            .frame(width: 8, height: 8)
//                    }
//                }
//            }
        }
//        .ignoresSafeArea()
    }
}

#Preview {
    OnboardingTabView(userDefaultsManager: UserDefaultsManager.shared)
}
