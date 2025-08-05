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
        VStack(alignment: .leading) {
            Divider()
            Toggle("하루 종일", isOn: $isAllDay)
            Divider()
            DatePickerView(date: $startDate, text: "시작", isAllDay: isAllDay)
                .padding(.top, 5)

            DatePickerView(date: $endDate, text: "종료", isAllDay: isAllDay)
                .padding(.bottom, 5)
            Divider()
            Spacer()
        }
        .padding()
    }
}

#Preview {
    @State var startDate = Date()
    @State var endDate = Date().addingTimeInterval(3600)
    @State var isAllDay = false

    return PeriodPickerView(
        startDate: $startDate,
        endDate: $endDate,
        isAllDay: $isAllDay
    )
}
