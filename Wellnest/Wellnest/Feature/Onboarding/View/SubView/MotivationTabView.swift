//
//  MotivationTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct MotivationTabView: View {
    @Binding var currentPage: Int
    @Binding var title: String

    var body: some View {
        VStack {
            Spacer()

            FilledButton(title: "다음") {
                withAnimation {
                    currentPage += 1
                }
            }
            .padding()
        }
        .onAppear {
            title = "동기부여 문구"
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
        MotivationTabView(currentPage: $currentPage, title: $title)
    }
}
