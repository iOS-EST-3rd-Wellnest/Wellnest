//
//  EndDateSelectorView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/11/25.
//

import SwiftUI

enum Mode { case none, date }

struct EndDateSelectorView: View {
    @Binding var mode: Mode
    @Binding var endDate: Date

    @State private var showCalendar: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.content) {
            // 1) "없음" 태그 (메뉴)
            HStack {
                Text("반복 종료")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Menu {
                    Button("안함") {
                        mode = .none
                        showCalendar = false
                    }
                    Button("날짜") {
                        mode = .date
                        // 날짜 모드로 바꿀 때 캘린더는 닫힌 상태로 시작
                        showCalendar = false
                        if endDate.timeIntervalSince1970 == 0 {
                            endDate = Date() // 최초 진입이라면 오늘로 세팅
                        }
                    }
                } label: {
                    SimpleTag(mode == .date ? "날짜" : "안함", isSelected: false)
                }
            }


            // 2) 날짜 모드일 때: "종료일", "yyyy.M.d" 태그 노출
            if mode == .date {
                HStack(spacing: 8) {
                    Text("종료 일")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        withAnimation(.easeInOut) {
                            showCalendar.toggle()
                        }
                    } label: {
                        SimpleTag(formatted(endDate), isSelected: showCalendar)
                    }
                    .buttonStyle(.plain)
                }

                // 3) 날짜 태그를 다시 누르면 캘린더 토글
                if showCalendar {
                    DatePicker(
                        "",
                        selection: $endDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .transition(.dropFromButton)
                }
            }
        }
    }

    // "2025.8.17" 형식 포맷터 (0 패딩 없이)
    private func formatted(_ date: Date?) -> String {
        guard let date else { return "" }
        let cal = Calendar(identifier: .gregorian)
        let c = cal.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 0
        let m = c.month ?? 0
        let d = c.day ?? 0
        return "\(y). \(m). \(d)"
    }
}

