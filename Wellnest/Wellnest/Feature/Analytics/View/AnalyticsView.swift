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

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                customNavigationHeader

                GeometryReader { geometry in
                    ScrollView {
                        VStack {
                            Color.clear
                                .frame(height: 1)
                                .background(
                                    GeometryReader { scrollGeometry in
                                        Color.clear
                                            .preference(key: ScrollOffsetPreferenceKey.self,
                                                      value: scrollGeometry.frame(in: .named("scroll")).minY)
                                    }
                                )
                                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                                    showDivider = offset < 0
                                }

                            if horizontalSizeClass == .regular {
                                iPadLayout
                            } else {
                                iPhoneLayout
                            }
                        }
                    }
                    .coordinateSpace(name: "scroll")
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .background(Color(.systemBackground))
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
            .padding(.vertical, 12)

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

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    AnalyticsView()
}
