//
//  AnalyticsView.swift
//  Wellnest
//
//  Created by junil on 8/11/25.
//

import SwiftUI

struct AnalyticsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                if horizontalSizeClass == .regular {
                    iPadLayout
                } else {
                    iPhoneLayout
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var iPhoneLayout: some View {
        VStack(spacing: Spacing.layout) {
            TitleHeaderView(name: .constant("홍길동"))
            PlanCompletionCardView()
            AIInsightCardView()

            ExerciseStatChartCardView()

            SleepStatChartCardView()

            MeditationStatCardView()
        }
        .padding(.horizontal)
        .padding(.top, Spacing.layout)
        .padding(.bottom, 100)
    }

    private var iPadLayout: some View {
        VStack(spacing: Spacing.layout) {
            TitleHeaderView(name: .constant("홍길동"))

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.layout),
                GridItem(.flexible(), spacing: Spacing.layout)
            ], spacing: Spacing.layout) {
                VStack(alignment: .leading, spacing: Spacing.layout) {
                    PlanCompletionCardView()
                    ExerciseStatChartCardView()
                }

                VStack(alignment: .leading, spacing: Spacing.layout) {
                    AIInsightCardView()
                    SleepStatChartCardView()
                    MeditationStatCardView()
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 20)
    }
}

#Preview {
    AnalyticsView()
}
