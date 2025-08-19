//
//  MoodCheckIn.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/19/25.
//

import SwiftUI
import Combine

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

struct MorningCheckInView: View {
    @State private var mood: Mood? = nil
    @State private var valence: Double = 0.2
    @State private var energy: Double = 0.6
    @State private var showNote = false
    @State private var note = ""

    var onSubmit: (MorningCheckIn) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // 1) 원탭 무드
            HStack(spacing: 12) {
                ForEach(Mood.allCases, id: \.self) { m in
                    Button {
                        mood = m
                    } label: {
                        Text(emoji(for: m))
                            .font(.system(size: 28))
                            .frame(width: 52, height: 52)
                            .background(mood == m ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(Text(a11y(for: m)))
                }
            }

            // 2) 2D 무드 맵 (Valence × Energy)
            ValenceEnergyPad(valence: $valence, energy: $energy)
                .frame(height: 180)

            // 3) 선택 메모
            DisclosureGroup(showNote ? "메모 닫기" : "한 줄 메모(선택)") {
                TextField("예: 머리가 맑아요 / 두통 있어요", text: $note)
            }
            .onTapGesture { withAnimation { showNote.toggle() } }

            Button(action: submit) {
                Text("기록하기")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(mood == nil)
        }
        .padding()
    }

    private func submit() {
        let checkin = MorningCheckIn(
            mood: mood ?? .meh,
            valence: valence,
            energy: energy,
            note: note.isEmpty ? nil : note
        )
        onSubmit(checkin)
        // 가벼운 햅틱 추천
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
    private func a11y(for m: Mood) -> String {
        switch m {
        case .great: return "매우 좋음"
        case .good:  return "좋음"
        case .meh:   return "보통"
        case .bad:   return "나쁨"
        case .awful: return "매우 나쁨"
        }
    }
}

struct ValenceEnergyPad: View {
    @Binding var valence: Double   // -1...+1 (가로)
    @Binding var energy: Double    //  0...1  (세로)
    @State private var dragging = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 그리드 배경
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                VStack {
                    Spacer()
                    Text("에너지")
                        .font(.caption2)
                        .padding(.bottom, 4)
                }
                HStack {
                    Text("부정")
                        .font(.caption2)
                        .rotationEffect(.degrees(-90))
                        .padding(.leading, 4)
                    Spacer()
                    Text("긍정")
                        .font(.caption2)
                        .rotationEffect(.degrees(90))
                        .padding(.trailing, 4)
                }
                // 포인터
                let x = (valence + 1) / 2 * geo.size.width
                let y = (1 - energy) * geo.size.height
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 18, height: 18)
                    .position(x: x.clamped(to: 0...geo.size.width),
                              y: y.clamped(to: 0...geo.size.height))
            }
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { g in
                    dragging = true
                    let nx = (g.location.x / geo.size.width).clamped(to: 0...1)
                    let ny = (g.location.y / geo.size.height).clamped(to: 0...1)
                    valence = nx * 2 - 1
                    energy  = 1 - ny
                }
                .onEnded { _ in dragging = false }
            )
        }
    }
}

fileprivate extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self {
        min(max(self, r.lowerBound), r.upperBound)
    }
}
