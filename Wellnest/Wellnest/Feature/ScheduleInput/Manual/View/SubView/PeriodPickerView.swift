//
//  PeriodPickerView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/3/25.
//

import SwiftUI

struct PeriodPickerView: View {
    var text: String = ""

    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isAllDay: Bool

    @State var date: Date = Date()
    @State private var showCalendar = false
    @State private var showTimePicker = false
    @State private var isStartPickerOpen = false
    @State private var isEndPickerOpen = false

    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $isAllDay) {
                Text("하루 종일")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .onChange(of: isAllDay) { newValue in
                        UIApplication.hideKeyboard()
                    }
            }
            .tint(.wellnestOrange)
            DatePickerView(
                text: "시작",
                date: $startDate,
                isAllDay: $isAllDay,
                isPresented: $isStartPickerOpen
            )
            .tint(.wellnestOrange)
            .padding(.top, 5)
            .onChange(of: startDate) { newValue in
                guard newValue.timeIntervalSince(endDate) >= 0 else { return }
                endDate = newValue.addingTimeInterval(3600)
            }
            .onChange(of: isStartPickerOpen) { newValue in
                if newValue {
                    if isEndPickerOpen {
                        isEndPickerOpen = false
                    }
                } // 시작 열면 종료 닫기
            }
            DatePickerView(
                text: "종료",
                date: $endDate,
                isAllDay: $isAllDay,
                isPresented: $isEndPickerOpen
            )
            .tint(.wellnestOrange)
            .onChange(of: endDate) { newValue in
                guard newValue.timeIntervalSince(startDate) <= 0 else { return }
                startDate = newValue.addingTimeInterval(-3600)
            }
            .onChange(of: isEndPickerOpen) { newValue in
                if newValue {
                    if isStartPickerOpen {
                        isStartPickerOpen = false
                    }
                } // 종료 열면 시작 닫기
            }
        }
    }

    // 날짜만 포맷
    func formattedDateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy. M. d"
        return formatter.string(from: date)
    }

    // 시간만 포맷
    func formattedTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
}
