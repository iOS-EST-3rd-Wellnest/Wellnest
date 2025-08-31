//
//  PlanCompletionCardView.swift
//  Wellnest
//
//  Created by junil on 8/11/25.
//

import SwiftUI
import CoreData

struct ScheduleProgressView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var viewModel: ScheduleProgressViewModel
    
    var scheduleProgressType: ScheduleProgressType = .today

    var body: some View {
        HStack(spacing: 0) {
            ProgressRingView(viewModel: viewModel, scheduleProgressType: scheduleProgressType)
                .padding()
            
            ProgressInfoView(viewModel: viewModel, scheduleProgressType: scheduleProgressType)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical)
                .padding(.leading, Spacing.content)
                
            ProgressFooterView(viewModel: viewModel, scheduleProgressType: scheduleProgressType)
                .padding(.bottom, Spacing.content)
                .padding(.trailing, Spacing.inline)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .if(UIDevice.current.userInterfaceIdiom == .pad) { content  in
            content
                .padding(.top, Spacing.inline)
        }
        .padding(.bottom)
        .padding(.horizontal, Spacing.content)
        .roundedBorder(cornerRadius: CornerRadius.large)
        .defaultShadow()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(.wellnestBackgroundCard)
        )
    }
}


// MARK: - ProgressRingView
private struct ProgressRingView: View {
    @ObservedObject var viewModel: ScheduleProgressViewModel
    @State private var scheduleCount = 0
    @State private var completedCount = 0
    @State private var completionRate: Double = 0.0
    @State private var progressIconName = "calendar.badge.plus"
    
    var scheduleProgressType: ScheduleProgressType = .today

    var body: some View {
        let lineWidth: CGFloat = 16
        let size: CGFloat = 100
        
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
                .frame(width: size, height: size)

            if scheduleCount > 0 {
                Circle()
                    .trim(from: 0, to: completionRate)
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .wellnestOrange],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
            }

            Image(systemName: progressIconName)
                .font(.system(size: 35, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .onAppear {
            setCompletedInfo(type: scheduleProgressType)
        }
    }
    
    private func setCompletedInfo(type: ScheduleProgressType) {
        switch type {
        case .today:
            scheduleCount = viewModel.todayScheduleCount
            completionRate = viewModel.todayCompletionRate
            progressIconName = viewModel.progressIconName
        case .weekly:
            scheduleCount = viewModel.weeklyScheduleCount
            completionRate = viewModel.weeklyCompletionRate
            progressIconName = viewModel.progressWeeklyIconName
        case .monthly:
            scheduleCount = viewModel.monthlyScheduleCount
            completionRate = viewModel.monthlyCompletionRate
            progressIconName = viewModel.progressMonthlyIconName
        }
    }
}

// MARK: - ProgressInfoView
private struct ProgressInfoView: View {
    @ObservedObject var viewModel: ScheduleProgressViewModel
    @State private var progressInfo = ( title: "일정이 없네요", description: "오늘 일정을\n추가해보세요.")
    @State private var scheduleCount = 0
    
    var scheduleProgressType: ScheduleProgressType = .today

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.content) {
            Text(progressInfo.title)
                .font(viewModel.todayScheduleCount > 0 ? .largeTitle : .title3)
                .bold()
            
            Text(progressInfo.description)
                .font(UIDevice.current.userInterfaceIdiom == .pad ? .body : .subheadline)
                .foregroundColor(.secondary)
        }
        .onAppear {
            setCompletedInfo(type: scheduleProgressType)
        }
    }
    
    private func setCompletedInfo(type: ScheduleProgressType) {
        switch type {
        case .today:
            progressInfo = viewModel.progressInfo
            scheduleCount = viewModel.todayScheduleCount
        case .weekly:
            progressInfo = viewModel.progressWeeklyInfo
            scheduleCount = viewModel.weeklyScheduleCount
        case .monthly:
            progressInfo = viewModel.progressMonthlyInfo
            scheduleCount = viewModel.monthlyScheduleCount
        }
    }
}

// MARK: - ProgressFooterView
private struct ProgressFooterView: View {
    @ObservedObject var viewModel: ScheduleProgressViewModel
    @State private var progressTitle = "오늘 일정"
    
    var scheduleProgressType: ScheduleProgressType = .today

    var body: some View {
        VStack(alignment: .trailing) {
            Spacer()
            Text(progressTitle)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .onAppear {
            setCompletedInfo(type: scheduleProgressType)
        }
    }
    
    private func setCompletedInfo(type: ScheduleProgressType) {
        switch type {
        case .today:
            progressTitle = viewModel.progressTitle
        case .weekly:
            progressTitle = viewModel.progressWeeklyTitle
        case .monthly:
            progressTitle = viewModel.progressMonthlyTitle
        }
    }
}

