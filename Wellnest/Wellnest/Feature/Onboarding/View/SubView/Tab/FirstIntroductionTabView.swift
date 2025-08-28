//
//  FirstIntroductionTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct FirstIntroductionTabView: View {
    @Binding var currentPage: Int
    @Binding var title: String

    let isIPad = OnboardingCardLayout.isIPad

    var body: some View {
        VStack {
            Spacer()

            VStack {
                Text("Wellnest")
                    .font(isIPad ? .system(size: 65) : .system(size: 45))
                    .fontWeight(.semibold)
                    .padding(.bottom)

                VStack {
                    Text("바쁜 일상 속에서도")
                    Text("건강하고 균형 잡힌 삶을 실현할 수 있도록 돕는,")
                    Text("AI 라이프스타일 플래너")
                }
                .font(isIPad ? .title2 : .body)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.bottom, isIPad ? 50 : 30)

                Image("firstIntro")
                    .resizable()
                    .scaledToFit()
                    .frame(height: isIPad ? 400 : 300)
            }

            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
        .safeAreaInset(edge: .bottom) {
            OnboardingButton(
                title: "다음",
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
    @State private var title = "동기부여 문구"

    var body: some View {
        FirstIntroductionTabView(currentPage: $currentPage, title: $title)
    }
}
