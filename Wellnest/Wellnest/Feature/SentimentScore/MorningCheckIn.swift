//
//  MorningCheckIn.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/20/25.
//

import Foundation

enum Mood: Int, CaseIterable { case great, good, meh, bad, awful }

struct MorningCheckIn: Identifiable {
    let id = UUID()
    var mood: Mood
    var valence: Double   // -1...+1
    var energy: Double    //  0...1
    var note: String?
    var timestamp: Date = .now

    // 🔹 Core ML 결과(옵션)
    var mlLabel: String? = nil         // "Pos"/"Neg"/"Neutral" 등
    var mlConfidence: Double? = nil    // 0.0 ~ 1.0
}
