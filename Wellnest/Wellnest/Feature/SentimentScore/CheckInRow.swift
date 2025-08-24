//
//  CheckInRow.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/20/25.
//

import SwiftUI

struct CheckInRow: View {
    let item: MorningCheckIn

    // 캐시된 DateFormatter (성능 좋음)
    private static let df: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M.d (E) a h:mm" // 예: 8.19 (화) 오전 7:30
        return f
    }()

    private func dateString(_ d: Date) -> String {
        Self.df.string(from: d)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji(for: item.mood))
                .font(.largeTitle)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(dateString(item.timestamp))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let note = item.note, !note.isEmpty {
                    Text(note).font(.body).lineLimit(2)
                }

                // 🔹 ML 결과 뱃지
                if let lbl = item.mlLabel, let conf = item.mlConfidence {
                    HStack(spacing: 6) {
                        Circle().fill(color(for: lbl)).frame(width: 8, height: 8)
                        Text("ML: \(pretty(lbl)) \(String(format: "%.0f", conf*100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()

            let score = sentimentalScore(mood: item.mood)
            Text(String(format: "%.0f", score * 100) + "%")
                .font(.headline)
                .monospacedDigit()
        }
        .padding(.vertical, 8)
    }

    private func emoji(for m: Mood) -> String {
        switch m {
        case .great: return "😀"
        case .good:  return "🙂"
        case .meh:   return "😐"
        case .bad:   return "🙁"
        case .awful: return "😫"
        }
    }

    private func color(for lbl: String) -> Color {
        let l = lbl.lowercased()
        if l.contains("pos") || l.contains("긍") { return .green }
        if l.contains("neg") || l.contains("부") { return .red }
        return .gray
    }
    private func pretty(_ lbl: String) -> String {
        switch lbl.lowercased() {
        case "pos", "positive", "긍정": return "긍정"
        case "neg", "negative", "부정": return "부정"
        case "neu", "neutral", "중립": return "중립"
        default: return lbl
        }
    }
}
