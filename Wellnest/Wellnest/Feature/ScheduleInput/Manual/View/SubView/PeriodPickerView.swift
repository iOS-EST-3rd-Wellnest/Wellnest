//
//  PeriodPickerView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/3/25.
//

import SwiftUI

struct PeriodPickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isAllDay: Bool

    @State var date: Date = Date()
    @State private var showCalendar = false
    @State private var showTimePicker = false
    var text: String = ""
    @State private var isStartPickerOpen = false
    @State private var isEndPickerOpen = false

//    var onChange: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading) {
            DatePickerView(date: $startDate, text: "시작", isAllDay: isAllDay, isPresented: $isStartPickerOpen)
                .padding(.top, 5)
                .onChange(of: startDate) { newValue in
                    endDate = newValue.addingTimeInterval(3600)
                }
                .onChange(of: isStartPickerOpen) { newValue in
                    if newValue {
                        if isEndPickerOpen { isEndPickerOpen = false }
                    } // 시작 열면 종료 닫기
                }

            DatePickerView(date: $endDate, text: "종료", isAllDay: isAllDay, isPresented: $isEndPickerOpen)
                .padding(.bottom, 5)
                .onChangeWithOldValue(of: endDate) { oldValue, newValue in
                    if newValue.timeIntervalSince(startDate) < 0 {
                        endDate = oldValue
                    }
                }
                .onChange(of: isEndPickerOpen) { newValue in
                    if newValue {
                        if isStartPickerOpen { isStartPickerOpen = false }
                    } // 종료 열면 시작 닫기
                }
        }
    }
    //                        }
//    var body: some View {
//        VStack(alignment: .leading) {
//            HStack(spacing: Spacing.content) {
//                Text(text)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                Spacer()
//                // 날짜 텍스트 버튼
//                Button {
//                    withAnimation {
//                        showCalendar.toggle()
//                        showTimePicker = false
//                        date = startDate
//                    }
//                } label: {
//                    Text(formattedDateOnly(startDate))
//                        .foregroundColor(showCalendar ? .blue : .black)
//                }
//                .padding(.horizontal, Spacing.layout)
//                .padding(.vertical, Spacing.content)
//                .foregroundColor(showCalendar ? .blue : .primary)
//                .background(showCalendar ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
//                .overlay(
//                    RoundedRectangle(cornerRadius: CornerRadius.large)
//                        .stroke(showCalendar ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
//                )
//                .cornerRadius(16)
//
//
//                // 시간 텍스트 버튼
//                if !isAllDay {
//                    Button {
//                        withAnimation {
//                            showTimePicker.toggle()
//                            showCalendar = false
//                            date = startDate
//                        }
//                    } label: {
//                        Text(formattedTimeOnly(startDate))
//                            .foregroundColor(showTimePicker ? .blue : .black)
//                    }
//                    .padding(.horizontal, Spacing.layout)
//                    .padding(.vertical, Spacing.content)
//                    .foregroundColor(showTimePicker ? .blue : .primary)
//                    .background(showTimePicker ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
//                    .overlay(
//                        RoundedRectangle(cornerRadius: CornerRadius.large)
//                            .stroke(showTimePicker ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
//                    )
//                    .cornerRadius(16)
//                }
//            }
//
//            if showCalendar {
//                DatePicker(
//                    "",
//                    selection: $date,
//                    displayedComponents: [.date]
//                )
//                .datePickerStyle(.graphical)
//                .labelsHidden()
//                .environment(\.locale, Locale(identifier: "ko_KR"))
//                .frame(minHeight: 350)
//                .background(Color.white)
//                .transition(.opacity)
//                .zIndex(1)
//            } else if showTimePicker {
//                // 시간 선택용 Wheel Picker (5분 간격)
//                MinuteIntervalWheelDatePicker(date: $date, minuteInterval: 5, isAllDay: false)
//                    .frame(height: 200)
//                    .transition(.opacity)
//            }
//        }
//        .animation(.easeInOut, value: showCalendar || showTimePicker)
//    }

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

//#Preview {
//    @State var startDate = Date()
//    @State var endDate = Date().addingTimeInterval(3600)
//    @State var isAllDay = false
//
//    return PeriodPickerView(
//        startDate: $startDate,
//        endDate: $endDate,
//        isAllDay: $isAllDay
//    )
//}
