//
//  PlanCompletionCardView.swift
//  Wellnest
//
//  Created by junil on 8/11/25.
//

import SwiftUI

struct PlanCompletionCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    let planData: PlanCompletionData

    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.large)
            .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
            .frame(minHeight: 150)
            .defaultShadow()
            .overlay {
                VStack(alignment: .leading, spacing: Spacing.content) {
                    HStack(spacing: Spacing.layout) {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 16)
                                .frame(width: 100, height: 100)

                            if planData.totalItems > 0 {
                                Circle()
                                    .trim(from: 0, to: planData.completionRate)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.green, .blue],
                                            startPoint: .topTrailing,
                                            endPoint: .bottomLeading
                                        ),
                                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                    )
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-90))
                            }

                            Image(systemName: planData.totalItems > 0 ? "flag.pattern.checkered" : "calendar.badge.plus")
                                .font(.system(size: 35, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)

                        VStack(alignment: .leading, spacing: Spacing.content) {
                            if planData.totalItems > 0 {
                                Text("\(Int(planData.completionRate * 100))%")
                                    .font(.largeTitle)
                                    .bold()

                                Text("오늘 일정이\n\(planData.remainingItems)개 남았어요")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("일정이 없네요")
                                    .font(.title3)
                                    .bold()

                                Text("오늘 일정을\n추가해보세요")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Spacer()
                            Text(planData.totalItems > 0 ? "오늘 달성률" : "오늘 일정")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
    }
}
