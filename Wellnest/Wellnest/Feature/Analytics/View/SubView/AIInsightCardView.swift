//
//  AIInsightCardView.swift
//  Wellnest
//
//  Created by junil on 8/11/25.
//

import SwiftUI

struct AIInsightCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.large)
            .fill(colorScheme == .dark ? Color(.gray) : .white)
            .frame(minHeight: 80)
            .defaultShadow()
            .overlay(alignment: .leading) {
                HStack(spacing: Spacing.content) {
                    Image(systemName: "lightbulb.max.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: Spacing.content) {
                        Text("AI 인사이트")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        Text("운동한 날엔 수면 시간이 평균 50분 증가했어요.")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()
                }
                .padding()
            }
    }
}
