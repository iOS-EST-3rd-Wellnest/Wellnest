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
    @State private var showDivider = false
    @State private var offsetY: CGFloat = .zero
    
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        ScrollView {
            VStack {
                SafeAreaBlurView(offsetY: $offsetY, space: .named("analyticsViewScroll"))
                
                customNavigationHeader
                
                if horizontalSizeClass == .regular {
                    iPadLayout
                } else {
                    iPhoneLayout
                }
            }
        }
        .background(Color(.systemBackground))
        .coordinateSpace(name: "analyticsViewScroll")
        .safeAreaBlur(offsetY: $offsetY)
    }

    private var customNavigationHeader: some View {
        VStack {
            HStack {
                Text("\(viewModel.healthData.userName)님의 건강지표")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            if showDivider {
                Divider()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .animation(.easeInOut(duration: 0.2), value: showDivider)
    }

    private var iPhoneLayout: some View {
        VStack(spacing: Spacing.layout) {
//            ScheduleProgressView(planData: viewModel.healthData.planCompletion)
            ScheduleProgressView(context: context)
//            AIInsightCardView(insight: viewModel.healthData.aiInsight)
            AIInsightView()
            ExerciseStatChartCardView(exerciseData: viewModel.healthData.exercise)
            SleepStatChartCardView(sleepData: viewModel.healthData.sleep)
        }
        .padding(.horizontal)
        .padding(.top, Spacing.layout)
        .padding(.bottom, 100)
    }

    private var iPadLayout: some View {
        VStack(spacing: Spacing.layout) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.layout),
                GridItem(.flexible(), spacing: Spacing.layout)
            ], spacing: Spacing.layout) {
                VStack(alignment: .leading, spacing: Spacing.layout) {
//                    ScheduleProgressView(planData: viewModel.healthData.planCompletion)
                    ScheduleProgressView(context: context)
                    ExerciseStatChartCardView(exerciseData: viewModel.healthData.exercise)
                }
                VStack(alignment: .leading, spacing: Spacing.layout) {
//                    AIInsightCardView(insight: viewModel.healthData.aiInsight)
                    AIInsightView()
                    SleepStatChartCardView(sleepData: viewModel.healthData.sleep)
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
