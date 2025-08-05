//
//  IntroductionView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct IntroductionTab: View {
    @Binding var currentPage: Int
//    let onNext: () -> Void
    
    var body: some View {
        VStack {
            OnboardingTitle(title: "앱 소개", description: "")

            Spacer()

            FilledButton(title: "다음") {
                currentPage += 1
            }
            .padding()
        }
    }
}

#Preview {
    Preview()
}

private struct Preview: View {
    @State private var currentPage = 0

    var body: some View {
        IntroductionTab(currentPage: $currentPage)
    }
}
