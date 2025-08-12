//
//  PlanCompletionCardView.swift
//  Wellnest
//
//  Created by junil on 8/11/25.
//

import SwiftUI

struct PlanCompletionCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    private let completionRate: Double = 0.88

    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.large)
            .fill(colorScheme == .dark ? Color(.gray) : .white)
            .frame(minHeight: 180)
            .defaultShadow()
            .overlay {
                HStack(spacing: 20) {
                    // 왼쪽 정보
                    VStack(alignment: .leading, spacing: Spacing.content) {
                        Text("목표달성")
                            .font(.title3)
                            .bold()

                        Text("\(Int(completionRate * 100))%")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)

                        Text("이번 주 달성률")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // 오른쪽 원형 차트
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: completionRate)
                            .stroke(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .topTrailing,
                                    endPoint: .bottomLeading
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                    }
                }
                .padding()
            }
    }
}
