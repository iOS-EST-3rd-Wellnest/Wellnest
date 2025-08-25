//
//  IntroductionTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct IntroductionTabView: View {
    @Binding var currentPage: Int
    @Binding var title: String

    var body: some View {
        VStack {
            Spacer()
            
            OnboardingButton(
                title: "다음",
                isDisabled: false,
                action: {
                    withAnimation { currentPage += 1 }
                },
                currentPage: $currentPage
            )
        }
        .background(Color(.systemBackground))
        .onAppear {
            title = "앱 소개"
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
        IntroductionTabView(currentPage: $currentPage, title: $title)
    }
}
