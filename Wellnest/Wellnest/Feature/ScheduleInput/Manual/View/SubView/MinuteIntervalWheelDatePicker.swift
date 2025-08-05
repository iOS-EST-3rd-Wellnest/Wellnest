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

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.minuteInterval = minuteInterval
        picker.locale = Locale(identifier: "ko_KR")
        picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        if uiView.date != date {
            uiView.setDate(date, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: MinuteIntervalWheelDatePicker

        init(_ parent: MinuteIntervalWheelDatePicker) {
            self.parent = parent
        }

        @objc func dateChanged(_ sender: UIDatePicker) {
            parent.date = sender.date
        }
    }
}
