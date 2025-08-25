//
//  MeditationStatCardView.swift
//  Wellnest
//
//  Created by junil on 8/12/25.
//

import SwiftUI

struct MeditationStatCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    let meditationData: MeditationData

    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.large)
            .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
            .frame(minHeight: 80)
            .defaultShadow()
            .overlay {
                HStack(spacing: Spacing.content) {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: Spacing.inline) {
                        Text("명상")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        HStack(alignment: .bottom, spacing: Spacing.inline) {
                            Text("주 \(meditationData.weeklyCount)회")
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text("성공")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }

                    Spacer()

                    HStack(spacing: Spacing.inline) {
                        Image(systemName: "arrow.up")
                            .font(.caption)
                            .foregroundColor(.green)

                        Text("+\(meditationData.changeCount)회")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                .padding()
            }
    }
}
