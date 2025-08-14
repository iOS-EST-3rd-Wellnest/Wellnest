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
    @StateObject private var viewModel = AnalyticsViewModel()

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
            TitleHeaderView(name: viewModel.healthData.userName)
            PlanCompletionCardView(planData: viewModel.healthData.planCompletion)
            AIInsightCardView(insight: viewModel.healthData.aiInsight)
            ExerciseStatChartCardView(exerciseData: viewModel.healthData.exercise)
            SleepStatChartCardView(sleepData: viewModel.healthData.sleep)
            MeditationStatCardView(meditationData: viewModel.healthData.meditation)
        }
        .padding(.horizontal)
        .padding(.top, Spacing.layout)
        .padding(.bottom, 100)
    }

    private var iPadLayout: some View {
        VStack(spacing: Spacing.layout) {
            TitleHeaderView(name: viewModel.healthData.userName)
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.layout),
                GridItem(.flexible(), spacing: Spacing.layout)
            ], spacing: Spacing.layout) {
                VStack(alignment: .leading, spacing: Spacing.layout) {
                    PlanCompletionCardView(planData: viewModel.healthData.planCompletion)
                    ExerciseStatChartCardView(exerciseData: viewModel.healthData.exercise)
                }
                VStack(alignment: .leading, spacing: Spacing.layout) {
                    AIInsightCardView(insight: viewModel.healthData.aiInsight)
                    SleepStatChartCardView(sleepData: viewModel.healthData.sleep)
                    MeditationStatCardView(meditationData: viewModel.healthData.meditation)
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
