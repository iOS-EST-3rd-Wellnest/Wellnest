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
        ScrollView(showsIndicators: false) {
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
            HStack(spacing: 0) {
                Group {
                    Text("\(viewModel.getUserName())")
                        .foregroundColor(.wellnestOrange)
                    
                    Text(" 님의 건강지표")
                        .foregroundColor(.primary)
                }
                .font(.title2)
                .fontWeight(.semibold)
                
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
            TabView {
                ForEach(ScheduleProgressType.allCases) {
                    ScheduleProgressView(scheduleProgressType: $0)
                        .padding(.horizontal)
                        .padding(.bottom, Spacing.inline)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: colorScheme == .dark ? .never : .always))
            .frame(minHeight: 200)
            
            Group {
                AIInsightView()
                ExerciseStatChartCardView(exerciseData: viewModel.healthData.exercise)
                SleepStatChartCardView(sleepData: viewModel.healthData.sleep)
            }
            .padding(.horizontal)
        }
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
                    ScheduleProgressView(scheduleProgressType: .today)
                    ScheduleProgressView(scheduleProgressType: .monthly)
                    ExerciseStatChartCardView(exerciseData: viewModel.healthData.exercise)
                }
                VStack(alignment: .leading, spacing: Spacing.layout) {
                    ScheduleProgressView(scheduleProgressType: .weekly)
                    AIInsightView()
                    SleepStatChartCardView(sleepData: viewModel.healthData.sleep)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 20)
    }
}
