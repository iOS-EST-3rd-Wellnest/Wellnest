//
//  ThirdIntroductionTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/27/25.
//

import SwiftUI

struct ThirdIntroductionTabView: View {
    @Binding var currentPage: Int
    @Binding var title: String

    @State private var isShaking = false

    let isIPad = OnboardingCardLayout.isIPad

    var body: some View {
        VStack {
            Spacer()

            VStack {
                Text("당신의 하루,")
                HStack {
                    Text("Wellnest")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.wellnestAccentPeach, .wellnestOrange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .fontWeight(.bold)
                        .rotationEffect(.degrees(isShaking ? -2 : 2), anchor: .bottom)
                        .offset(x: isShaking ? -1.5 : 1.5)
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                            ) {
                                isShaking.toggle()
                            }
                        }

                    Text("와 함께 ")
                }

                Text("시작해볼까요?")
            }
            .font(isIPad ? .system(size: 42) : .title)
            .fontWeight(.semibold)

            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .safeAreaInset(edge: .bottom) {
            OnboardingButton(
                title: "시작하기",
                isDisabled: false,
                action: {
                    withAnimation { currentPage += 1 }
                },
                currentPage: $currentPage
            )
        }
        .onAppear {
            title = ""
        }
    }
}

#Preview {
    Preview()
}

private struct Preview: View {
    @State private var currentPage = 0
    @State private var title = "앱 소개"

    var body: some View {
        ThirdIntroductionTabView(currentPage: $currentPage, title: $title)
    }
}
