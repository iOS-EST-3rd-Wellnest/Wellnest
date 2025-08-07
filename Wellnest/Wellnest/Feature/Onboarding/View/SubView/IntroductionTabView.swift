//
//  IntroductionTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct IntroductionTabView: View {
    @Binding var currentPage: Int
    
    var body: some View {
        VStack {
            OnboardingTitle(title: "앱 소개", description: "", currentPage: currentPage, onBack: { withAnimation { currentPage -= 1 } })

            Spacer()

            FilledButton(title: "다음") {
                withAnimation {
                    currentPage += 1
                }
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
        IntroductionTabView(currentPage: $currentPage)
    }
}
