//
//  MotivationTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct MotivationTabView: View {
    @Binding var currentPage: Int

    var body: some View {
        VStack {
            OnboardingTitle(title: "동기부여 문구", description: "")

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
        MotivationTabView(currentPage: $currentPage)
    }
}
