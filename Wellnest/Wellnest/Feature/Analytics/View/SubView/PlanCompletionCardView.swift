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
    private let title = "목표달성"
    private let subtitle = ""
    private let description = ""

    var body: some View {
        HStack(spacing: 20) {
            // 왼쪽 정보
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryTextColor)
                }

                Text("\(Int(completionRate * 100))%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(primaryTextColor)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            // 오른쪽 원형 차트
            ZStack {
                // 배경 원
                Circle()
                    .stroke(
                        Color.gray.opacity(0.3),
                        lineWidth: 8
                    )
                    .frame(width: 120, height: 120)

                // 진행률 원
                Circle()
                    .trim(from: 0, to: completionRate)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                // 중앙 텍스트
                VStack(spacing: 2) {
                    Text(subtitle)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryTextColor)

                    Text(title)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(20)
        .background(cardBackgroundColor)
        .cornerRadius(16)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }

    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.15) : Color(.systemGray6)
    }
}
