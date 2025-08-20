//
//  CheckInStore.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/20/25.
//

import SwiftUI

// MARK: - 간단 저장소 (UserDefaults 기반)
final class CheckInStore: ObservableObject {
    @Published var items: [MorningCheckIn] = []

    private let storageKey = "morning.checkins.v1"

    init() { load() }

    func add(_ c: MorningCheckIn) {
        items.insert(c, at: 0)
        save()
    }

    private func save() {
        do {
            let enc = try JSONEncoder().encode(items.map(EncodableCheckIn.init))
            UserDefaults.standard.set(enc, forKey: storageKey)
        } catch {
            print("Save error:", error)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let arr = try JSONDecoder().decode([EncodableCheckIn].self, from: data)
            items = arr.map { $0.model }
        } catch {
            print("Load error:", error)
        }
    }

    // MorningCheckIn이 Codable이 아니어도 저장 가능하도록 래핑
    struct EncodableCheckIn: Codable {
        let mood: Int
        let valence: Double
        let energy: Double
        let note: String?
        let timestamp: Date

        init(_ c: MorningCheckIn) {
            mood = c.mood.rawValue
            valence = c.valence
            energy = c.energy
            note = c.note
            timestamp = c.timestamp
        }

        var model: MorningCheckIn {
            MorningCheckIn(
                mood: Mood(rawValue: mood) ?? .meh,
                valence: valence,
                energy: energy,
                note: note,
                timestamp: timestamp
            )
        }
    }
}

// MARK: - 점수 계산(원한다면 UI에 노출)
func sentimentalScore(mood: Mood, valence: Double, energy: Double) -> Double {
    // great→awful 순으로 1.0 → 0.0
    let moodBase = [1.0, 0.75, 0.5, 0.25, 0.0][mood.rawValue]
    return 0.5 * moodBase + 0.3 * ((valence + 1) / 2) + 0.2 * energy
}
