//
//  CheckInMainView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/20/25.
//

import SwiftUI

// MARK: - 메인 화면: MorningCheckInView 사용
struct CheckInMainView: View {
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

                        print("\(label), \(conf)")
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
                Spacer()

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

#Preview {
    CheckInMainView()
}
