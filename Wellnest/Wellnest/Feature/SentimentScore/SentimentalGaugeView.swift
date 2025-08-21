//
//  SentimentalGaugeView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/21/25.
//

import SwiftUI

// MARK: - SentimentalGaugeView.swift

public struct SentimentalGaugeView: View {
    public var score: Double // 0..100
    public var subtitle: String?
    public var breakdown: (weather: Double?, mood: Double?, health: Double?) = (nil,nil,nil)
    public var feedback: SentimentalFeedback?


    public init(score: Double, subtitle: String? = nil, breakdown: (Double?,Double?,Double?) = (nil,nil,nil), feedback: SentimentalFeedback? = nil) {
        self.score = score; self.subtitle = subtitle; self.breakdown = breakdown
        self.feedback = feedback
    }

    public var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(lineWidth: 16)
                    .opacity(0.15)
                Circle()
                    .trim(from: 0, to: CGFloat(max(0, min(1, score/100))))
                    .stroke(style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: score)
                VStack(spacing: 4) {
                    Text("\(Int(score.rounded()))")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text("Sentimental Score")
                        .font(.footnote).foregroundStyle(.secondary)
                    if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
                }
            }
            .frame(width: 200, height: 200)

            // Breakdown bars
            VStack(spacing: 8) {
                BreakdownRow(label: "날씨", value01: breakdown.weather)
                BreakdownRow(label: "감정", value01: breakdown.mood)
                BreakdownRow(label: "건강", value01: breakdown.health)
//                BreakdownRow(label: "일정", value01: breakdown.calendar)
            }
            // ✅ 추가: 피드백 카드
              if let feedback {
                  FeedbackCardView(feedback: feedback)
                      .transition(.opacity.combined(with: .move(edge: .bottom)))
                      .accessibilityElement(children: .contain)
              }
        }
        .padding()
    }

    struct BreakdownRow: View {
        var label: String
        var value01: Double?
        var body: some View {
            HStack {
                Text(label).frame(width: 44, alignment: .leading).font(.caption)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6).opacity(0.12)
                        RoundedRectangle(cornerRadius: 6)
                            .frame(width: CGFloat((value01 ?? 0.5)) * geo.size.width)
                            .animation(.easeInOut(duration: 0.6), value: value01)
                    }
                }
                .frame(height: 10)
                Text(value01.map { String(format: "%.0f", $0*100) } ?? "—")
                    .font(.caption2).frame(width: 36, alignment: .trailing)
            }
            .frame(height: 18)
        }
    }
}


