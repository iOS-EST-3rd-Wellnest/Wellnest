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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("하루 종일", isOn: $isAllDay)
            DatePickerView(date: $startDate, text: "시작", isAllDay: isAllDay)
            DatePickerView(date: $endDate, text: "종료", isAllDay: isAllDay)
        }
    }
}
