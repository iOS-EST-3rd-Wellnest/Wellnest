//
//  MorningCheckIn.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/20/25.
//

import Foundation

enum Mood: Int, CaseIterable {
    case great, good, meh, bad, awful

    var emoji: String {
        switch self {
        case .great: return "😀"
        case .good:  return "🙂"
        case .meh:   return "😐"
        case .bad:   return "🙁"
        case .awful: return "😫"
        }
    }
    var state: String {
        switch self {
        case .great: return "매우 좋음"
        case .good:  return "좋음"
        case .meh:   return "보통"
        case .bad:   return "나쁨"
        case .awful: return "매우 나쁨"
        }
    }

    var score: Double {
        switch self {
        case .great: return 1.00
        case .good:  return 0.75
        case .meh:   return 0.50
        case .bad:   return 0.35
        case .awful: return 0.05
        }
    }

}

struct MorningCheckIn: Identifiable {
    let id = UUID()
    var mood: Mood
    var note: String?
    var timestamp: Date = .now

    // 🔹 Core ML 결과(옵션)
    var mlLabel: String? = nil         // "Pos"/"Neg"/"Neutral" 등
    var mlConfidence: Double? = nil    // 0.0 ~ 1.0
}
