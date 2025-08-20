//
//  MorningCheckInView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/20/25.
//

import SwiftUI

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

