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
        HStack(spacing: 12) {
            Text("💡")
                .font(.title)

            VStack(alignment: .leading, spacing: 4) {
                Text("AI 인사이트")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)

                Text("운동한 날엔 수면 시간이 평균 50분 증가했어요.")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding(.vertical)
        .padding(.leading)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }

    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.15) : Color(.systemGray6)
    }
}
