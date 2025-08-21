//
//  FeedbackCardView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/21/25.
//

import SwiftUI

public struct FeedbackCardView: View {
    public let feedback: SentimentalFeedback
    @State private var expanded: Bool = true

    public init(feedback: SentimentalFeedback) {
        self.feedback = feedback
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(feedback.headline)
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        expanded.toggle()
                    }
                } label: {
                    Image(systemName: expanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                        .imageScale(.medium)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(expanded ? "접기" : "펼치기")
                }
            }

            Text(feedback.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if expanded {
                if !feedback.strengths.isEmpty {
                    Divider().opacity(0.2)
                    Label("잘한 점", systemImage: "checkmark.circle")
                        .font(.subheadline).bold()
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(feedback.strengths.prefix(3)).indices, id: \.self) { idx in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "checkmark.seal.fill").imageScale(.small)
                                Text(feedback.strengths[idx]).font(.footnote)
                            }
                        }
                    }
                }

                if !feedback.suggestions.isEmpty {
                    Divider().opacity(0.2)
                    Label("오늘의 팁", systemImage: "lightbulb.fill")
                        .font(.subheadline).bold()
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(feedback.suggestions.prefix(3)).indices, id: \.self) { idx in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "circle.fill").font(.system(size: 6))
                                Text(feedback.suggestions[idx]).font(.footnote)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .shadow(radius: 2, y: 1)
        )
        .accessibilityElement(children: .contain)
    }
}

