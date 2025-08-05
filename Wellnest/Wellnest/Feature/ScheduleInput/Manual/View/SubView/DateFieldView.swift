//
//  DateFieldView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/4/25.
//

import SwiftUI

struct DatePickerView: View {
    @Binding var date: Date
    @State private var showCalendar = false
    @State private var showTimePicker = false
    var text: String = ""
    var isAllDay: Bool = false
    var isOpen: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {


            HStack(spacing: Spacing.content) {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                // 날짜 텍스트 버튼
                Button {
                    withAnimation {
                        showCalendar.toggle()
                        showTimePicker = false
                    }
                } label: {
                    Text(formattedDateOnly(date))
                        .foregroundColor(showCalendar ? .blue : .black)
                }
                .padding(.horizontal, Spacing.layout)
                .padding(.vertical, Spacing.content)
                .foregroundColor(showCalendar ? .blue : .primary)
                .background(showCalendar ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .stroke(showCalendar ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(16)

                // 시간 텍스트 버튼
                if !isAllDay {
                    Button {
                        withAnimation {
                            showTimePicker.toggle()
                            showCalendar = false
                        }
                    } label: {
                        Text(formattedTimeOnly(date))
                            .foregroundColor(showTimePicker ? .blue : .black)
                    }
                    .padding(.horizontal, Spacing.layout)
                    .padding(.vertical, Spacing.content)
                    .foregroundColor(showTimePicker ? .blue : .primary)
                    .background(showTimePicker ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .stroke(showTimePicker ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(16)
                }
            }

            // 날짜 선택용 캘린더
            if showCalendar {
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ko_KR"))
                .frame(minHeight: 350)
                .background(Color.white)
                .transition(.opacity)
                .zIndex(1)
            } else if showTimePicker {
                // 시간 선택용 Wheel Picker (5분 간격)
                if showTimePicker {
                    MinuteIntervalWheelDatePicker(date: $date, minuteInterval: 5, isAllDay: false)
                        .frame(height: 200)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut, value: showCalendar || showTimePicker)
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
