//
//  SwiftUIView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/4/25.
//

import SwiftUI

struct MinuteIntervalWheelDatePicker: UIViewRepresentable {
    @Binding var date: Date
    var minuteInterval: Int = 5
    var isAllDay: Bool = false
    var minimumDate: Date? = nil
    var maximumDate: Date? = nil

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "ko_KR")
        picker.minuteInterval = minuteInterval
        picker.datePickerMode = isAllDay ? .date : .dateAndTime
        picker.minimumDate = minimumDate
        picker.maximumDate = maximumDate
        picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        if uiView.date != date {
            uiView.setDate(date, animated: true)
        }
        uiView.minuteInterval = minuteInterval
        uiView.datePickerMode = isAllDay ? .date : .dateAndTime
        uiView.minimumDate = minimumDate
        uiView.maximumDate = maximumDate
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        let parent: MinuteIntervalWheelDatePicker

        init(_ parent: MinuteIntervalWheelDatePicker) {
            self.parent = parent
        }

        @objc func dateChanged(_ sender: UIDatePicker) {
            parent.date = sender.date
        }
    }
}
