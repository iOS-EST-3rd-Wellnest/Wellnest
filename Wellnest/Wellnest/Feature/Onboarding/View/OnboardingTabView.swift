//
//  OnboardingTableView.swift
//  Wellnest
//
//  Created by 정소이 on 8/1/25.
//

import SwiftUI

// TODO: 희정님이 만들어두신 Shared/View/FilledButton.swift 사용하기

struct OnboardingTitle: View {
    let title: String
    let description: String?

    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
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

struct UserInfoSectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.callout)
            .fontWeight(.semibold)
            .padding(.vertical)
            .padding(.leading, 28)
    }
}

struct OnboardingTabView: View {
    @AppStorage("isOnboarding") var isOnboarding: Bool = false

    @State private var currentPage: Int = 0

//    init(startPage: Int = 0) {
//        _currentPage = State(initialValue: startPage)
//    }

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                MotivationTab(currentPage: $currentPage)
                    .tag(0)

                IntroductionTab(currentPage: $currentPage)
                    .tag(1)

                IntroductionTab(currentPage: $currentPage)
                    .tag(2)

                UserInfoTab(currentPage: $currentPage)
                    .tag(3)

                WellnessGoalTab(currentPage: $currentPage)
                    .tag(4)

                VStack {
                    OnboardingTitle(title: "선호 활동", description: "평소에 선호하는 운동이나 활동을 골라주세요.")

                    Spacer()

                    FilledButton(title: "다음") {
                        currentPage = 6
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .tag(5)

                VStack {
                    OnboardingTitle(title: "활동 시간대", description: "앞에서 선택하신 활동은 주로 언제 하시나요?")

                    Spacer()

                    FilledButton(title: "다음") {
                        currentPage = 7
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .tag(6)

                VStack {
                    OnboardingTitle(title: "선호 날씨", description: "평소에 어떤 날씨를 좋아하시나요?")

                    Spacer()

                    FilledButton(title: "다음") {
                        currentPage = 8
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .tag(7)

                VStack {
                    OnboardingTitle(title: "현재 건강 상태", description: "현재 건강 상태에 해당하는 특별한 이슈가 있나요?")

                    Spacer()

                    FilledButton(title: "완료") {
                        isOnboarding = true
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .tag(8)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

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
    }
}

#Preview {
    OnboardingTabView()
}
