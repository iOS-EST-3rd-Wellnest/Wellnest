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
                    // iPad Layout
                    iPadLayout
                } else {
                    // iPhone Layout
                    iPhoneLayout
                }
            }
            .navigationTitle("분석")
            .navigationBarTitleDisplayMode(.large)
            .background(backgroundColor)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var iPhoneLayout: some View {
        VStack(spacing: 16) {
            PlanCompletionCardView()
            AIInsightCardView()
            HealthStatsSectionView()
            ChartSectionView()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var iPadLayout: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20)
        ], spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                PlanCompletionCardView()
                HealthStatsSectionView()
            }

            VStack(alignment: .leading, spacing: 16) {
                AIInsightCardView()
                ChartSectionView()
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 20)
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? .black : Color(.systemBackground)
    }
}

#Preview {
    AnalyticsView()
}
