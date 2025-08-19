//
//  CheckInStore.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/19/25.
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

                HStack(spacing: 10) {
                    Label("Valence \(String(format: "%.2f", item.valence))", systemImage: "face.smiling")
                    Label("Energy \(String(format: "%.2f", item.energy))", systemImage: "bolt.fill")
                }
                .font(.caption)
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

            let score = sentimentalScore(mood: item.mood, valence: item.valence, energy: item.energy)
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

// MARK: - 메인 화면: MorningCheckInView 사용
struct ContentView: View {
    @StateObject private var store = CheckInStore()
    @State private var showSaved = false
    let THRESHOLD = 0.60

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // 1) 아침 체크인 입력 (핵심: MorningCheckInView 사용)
                MorningCheckInView { checkin in
                    var c = checkin
                    if let note = c.note, !note.isEmpty,
                       let (label, conf) = SentimentService.shared.predict(from: note) {

                        // 신뢰도 임계치 적용(선택): 낮으면 Neutral로 정규화
                        let normalized: String = (conf >= THRESHOLD) ? label : "Neutral"
                        c.mlLabel = normalized
                        c.mlConfidence = conf
                    }
                    store.add(c)
                    showSaved = true
                }
                .padding(.bottom, 8)

                Divider()

                // 2) 최근 기록 목록
                List {
                    Section("최근 기록") {
                        ForEach(store.items.prefix(20)) { item in
                            CheckInRow(item: item)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("아침 체크인")
            .alert("저장 완료 🎉", isPresented: $showSaved) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("기록이 저장되었어요.")
            }
        }
    }
}
