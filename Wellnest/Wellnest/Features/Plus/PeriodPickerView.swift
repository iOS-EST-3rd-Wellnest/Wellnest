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
                DatePicker(
                    "",
                    selection: Binding(
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
                    in: dateRange ?? Date.distantPast...Date.distantFuture,
                    displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.wheel)
                .transition(.move(edge: .bottom))
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
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                onTap()
            } label: {
                HStack {
                    Text(formattedDate(date, isAllDay: isAllDay))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(isActive ? .blue : .black)
                }
                .foregroundColor(.primary)
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func formattedDate(_ date: Date, isAllDay: Bool) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yy. M. d(E)" // 예: 25.8.3(일)
        let dateString = dateFormatter.string(from: date)

        if isAllDay {
            return dateString
        } else {
            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "ko_KR")
            timeFormatter.dateFormat = "a h:mm" // 예: 오전 2:00
            let timeString = timeFormatter.string(from: date)
            return "\(dateString)\n\(timeString)"
        }
    }
}
