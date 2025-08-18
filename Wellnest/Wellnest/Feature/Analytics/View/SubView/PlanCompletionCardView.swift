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
            .fill(colorScheme == .dark ? Color(.gray) : .white)
            .frame(minHeight: 150)
            .defaultShadow()
            .overlay {
                VStack(alignment: .leading, spacing: Spacing.content) {
                    HStack(spacing: Spacing.layout) {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 16)
                                .frame(width: 100, height: 100)
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
                            Image(systemName: "flag.pattern.checkered")
                                .font(.system(size: 35, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)

                        VStack(alignment: .leading, spacing: Spacing.content) {
                            Text("\(Int(planData.completionRate * 100))%")
                                .font(.largeTitle)
                                .bold()
                            Text("오늘 일정이\n\(planData.remainingItems)개 남았어요")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Spacer()
                            Text("오늘 달성률")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
    }
}
