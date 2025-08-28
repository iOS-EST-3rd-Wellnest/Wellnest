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
    @StateObject private var viewModel: ScheduleProgressViewModel
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: ScheduleProgressViewModel(context: context))
    }

    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.large)
            .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
            .frame(minHeight: 150)
            .defaultShadow()
            .overlay {
                VStack(alignment: .leading, spacing: Spacing.content) {
                    HStack(spacing: Spacing.layout) {
                        ProgressRingView(viewModel: viewModel)
                        .padding(8)
                        
                        ProgressInfoView(viewModel: viewModel)
                        
                        Spacer()

                        ProgressFooterView(viewModel: viewModel)
                    }
                }
                .padding()
            }
    }
}


// MARK: - ProgressRingView
private struct ProgressRingView: View {
    @ObservedObject var viewModel: ScheduleProgressViewModel

    var body: some View {
        let lineWidth: CGFloat = 16
        let size: CGFloat = 100
        
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
                .frame(width: size, height: size)

            if viewModel.todayScheduleCount > 0 {
                Circle()
                    .trim(from: 0, to: viewModel.todayCompletionRate)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
            }

            Image(systemName: viewModel.progressIconName)
                .font(.system(size: 35, weight: .bold))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - ProgressInfoView
private struct ProgressInfoView: View {
    @ObservedObject var viewModel: ScheduleProgressViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.content) {
            Text(viewModel.progressInfo.title)
                .font(viewModel.todayScheduleCount > 0 ? .largeTitle : .title3)
                .bold()
            
            Text(viewModel.progressInfo.description)
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - ProgressFooterView
private struct ProgressFooterView: View {
    @ObservedObject var viewModel: ScheduleProgressViewModel

    var body: some View {
        VStack(alignment: .trailing) {
            Spacer()
            Text(viewModel.progressTitle)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
}

