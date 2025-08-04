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

    @State private var activePicker: ActivePicker? = nil

    private enum ActivePicker {
        case start
        case end
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("하루 종일", isOn: $isAllDay)
            HStack(spacing: 16) {
                dateField(label: "시작", date: startDate, isActive: activePicker == .start) {
                    withAnimation {
                        activePicker = activePicker == .start ? nil : .start
                    }
                }

                Image(systemName: "chevron.right")
                    .padding(.top, 30)
                    .foregroundColor(.secondary)

                dateField(label: "종료", date: endDate, isActive: activePicker == .end) {
                    withAnimation {
                        activePicker = activePicker == .end ? nil : .end
                    }
                }

            }

            let dateRange: ClosedRange<Date>? = {
                if activePicker == .end {
                    return startDate...Date.distantFuture
                } else {
                    return nil
                }
            }()

            if let picker = activePicker {

                MinuteIntervalWheelDatePicker(
                    date: Binding(
                        get: {
                            picker == .start ? startDate : endDate
                        },
                        set: { newValue in
                            if picker == .start {
                                startDate = newValue
                                if endDate < newValue {
                                    endDate = newValue
                                }
                            } else {
                                endDate = newValue
                            }
                        }
                    ),
                    minuteInterval: 5,
                    isAllDay: isAllDay,
                    minimumDate: dateRange?.lowerBound,
                    maximumDate: dateRange?.upperBound
                )
                .frame(maxWidth: .infinity, maxHeight: 200)
                .transition(.opacity)
                .padding(.top, -25)
            }
        }
        .animation(.easeInOut, value: activePicker)
    }
}

extension PeriodPickerView {

    @ViewBuilder
    private func dateField(
        label: String,
        date: Date,
        isActive: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            Button {
                UIApplication.hideKeyboard()
                onTap()
            } label: {
                HStack {
                    formattedDateText(date, isAllDay: isAllDay)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(isActive ? .blue : .black)
                        .frame(height: isAllDay ? 20 : 45)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func formattedDateText(_ date: Date, isAllDay: Bool) -> Text {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yy. M. d(E)"
        let dateString = dateFormatter.string(from: date)

        if isAllDay {
            return Text(dateString)
                .font(.headline)
        } else {
            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "ko_KR")
            timeFormatter.dateFormat = "a h:mm"
            let timeString = timeFormatter.string(from: date)

            return Text(dateString)
                .font(.subheadline)
                + Text("\n")
                + Text(timeString)
                .font(.headline)
        }
    }
}
