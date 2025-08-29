//
//  DateFieldView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/4/25.
//

import SwiftUI

struct DatePickerView: View {
    @Environment(\.colorScheme) private var colorScheme
    var text: String = ""
    
    @Binding var date: Date
    @Binding var isAllDay: Bool
    @Binding var isPresented: Bool

    @State private var showCalendar = false
    @State private var showTimePicker = false

    var onButtonTap: (() -> Void)? = nil

    var selectedDate: Bool {
        return isPresented && showCalendar
    }

    var selectedTime: Bool {
        return isPresented && showTimePicker
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.content) {
            HStack(spacing: Spacing.content) {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                // 날짜 텍스트 버튼
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        onButtonTap?()

                        if isPresented {
                            // 이미 보여짐
                            if showCalendar {
                                // 만약 date라면?
                                showCalendar = false
                                isPresented = false
                            } else if showTimePicker {
                                // time이라면?
                                showCalendar = true
                                showTimePicker = false
                            }
                        } else {
                            // 새로 열어야함
                            isPresented = true
                            showCalendar = true
                            showTimePicker = false
                        }
                    }
                } label: {
                    Text(formattedDateOnly(date))
                        .foregroundColor(selectedDate ? .wellnestOrange : (colorScheme == .dark ? .white : .black))
                }
                .padding(.horizontal, Spacing.layout)
                .padding(.vertical, Spacing.content)
                .foregroundColor(selectedDate ? .wellnestOrange : .primary)
                .background(selectedDate ? Color.wellnestOrange.opacity(0.2) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .stroke(selectedDate ? .wellnestOrange : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(16)

                // 시간 텍스트 버튼
                if !isAllDay {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            onButtonTap?()

                            if isPresented {
                                // 이미 보여짐
                                if showTimePicker {
                                    // 그게 만약 Time이라면?
                                    showTimePicker = false
                                    isPresented = false
                                } else if showCalendar {
                                    // Date라면?
                                    showCalendar = false
                                    showTimePicker = true
                                }
                            } else {
                                // 보여지지 않음
                                isPresented = true
                                showTimePicker = true
                                showCalendar = false
                            }
                        }
                    } label: {
                        Text(formattedTimeOnly(date))
                            .foregroundColor( selectedTime ? .wellnestOrange : (colorScheme == .dark ? .white : .black))
                    }
                    .padding(.horizontal, Spacing.layout)
                    .padding(.vertical, Spacing.content)
                    .foregroundColor(selectedTime ? .wellnestOrange : .primary)
                    .background(selectedTime ? Color .wellnestOrange.opacity(0.2) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .stroke(selectedTime ? .wellnestOrange : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(16)
                }

            }

            if (isAllDay && isPresented) || selectedDate {
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ko_KR"))
                .frame(minHeight: 350)
                .transition(.dropFromButton)
                .zIndex(1)
            } else if selectedTime {
                // 시간 선택용 Wheel Picker (5분 간격)
                MinuteIntervalWheelDatePicker(date: $date, minuteInterval: 5, isAllDay: false)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .transition(.dropFromButton)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showCalendar || showTimePicker)
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

extension AnyTransition {
    static var dropFromButton: AnyTransition {
        AnyTransition.modifier(
            active: OffsetAndFade(offsetY: -10, opacity: 0),
            identity: OffsetAndFade(offsetY: 0, opacity: 1)
        )
    }

    private struct OffsetAndFade: ViewModifier {
        let offsetY: CGFloat
        let opacity: Double

        func body(content: Content) -> some View {
            content
                .offset(y: offsetY)
                .opacity(opacity)
        }
    }
}
