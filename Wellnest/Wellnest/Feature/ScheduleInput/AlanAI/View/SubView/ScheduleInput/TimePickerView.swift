//
//  TimePickerView.swift
//  Wellnest
//
//  Created by junil on 8/7/25.
//

import SwiftUI

struct TimePickerView: View {
    var text: String = ""

    @Binding var time: Date
    @Binding var isPresented: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.content) {
            HStack(spacing: Spacing.content) {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        UIApplication.hideKeyboard()
                        time = roundedUpToFiveMinutes(time)
                        isPresented.toggle()
                    }
                } label: {
                    Text(formattedTimeOnly(time))
                        .foregroundColor(isPresented ? .wellnestOrange : .primary)
                }
                .padding(.horizontal, Spacing.layout)
                .padding(.vertical, Spacing.content)
                .foregroundColor(isPresented ? .wellnestOrange : .primary)
                .background(
                    isPresented ?
                    Color.wellnestOrange.opacity(0.2) :
                    (colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .stroke(
                            isPresented ? Color.wellnestOrange :
                            (colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)),
                            lineWidth: 1
                        )
                )
                .cornerRadius(16)
            }

            if isPresented {
                MinuteIntervalWheelDatePicker(date: $time, minuteInterval: 5, isAllDay: false)
                    .tint(.wellnestOrange)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(
                        // Picker 배경색 Dark Mode 대응
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                    )
                    .transition(.dropFromButton)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isPresented)
    }

    func formattedTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: roundedUpToFiveMinutes(date))
    }

    func roundedUpToFiveMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = components.minute ?? 0
        let remainder = minute % 5
        let minutesToAdd = remainder == 0 ? 0 : (5 - remainder)
        return calendar.date(byAdding: .minute, value: minutesToAdd, to: date) ?? date
    }
}
