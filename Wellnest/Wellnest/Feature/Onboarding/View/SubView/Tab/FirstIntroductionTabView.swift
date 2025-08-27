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

    var body: some View {
        VStack {
            Text("Wellnest")
                .font(.system(size: 50))
                .fontWeight(.semibold)
                .padding(.top, 70)
                .padding(.bottom)

            VStack {
                Text("바쁜 일상 속에서도")
                Text("건강하고 균형 잡힌 삶을 실현할 수 있도록 돕는,")
                Text("AI 라이프스타일 플래너")
            }
            .padding(.bottom, 30)

            Image("firstIntroduction")
                .resizable()
                .scaledToFit()
                .frame(height: 430)
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
