//
//  SinglePlanDateTimeSection.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct SinglePlanDateTimeSection: View {
    @Binding var singleDate: Date
    @Binding var singleStartTime: Date
    @Binding var singleEndTime: Date
    let onStartTimeChange: (Date) -> Void

    @State private var isDateOpen = false
    @State private var isStartTimeOpen = false
    @State private var isEndTimeOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.layout) {
            Text("일정 설정")
                .font(.headline)
                .fontWeight(.semibold)

            VStack {
                DatePickerView(text: "시작", date: $singleStartTime, isAllDay: .constant(false), isPresented: $isStartTimeOpen)
                    .onChange(of: singleStartTime) { newValue in
                        onStartTimeChange(newValue)
                    }
                    .onChange(of: isStartTimeOpen) { newValue in
                        if newValue {
                            isDateOpen = false
                            isEndTimeOpen = false
                        }
                    }

                DatePickerView(text: "종료", date: $singleEndTime, isAllDay: .constant(false), isPresented: $isEndTimeOpen)
                    .onChangeWithOldValue(of: singleEndTime) { oldValue, newValue in
                        if newValue.timeIntervalSince(singleStartTime) < 0 {
                            singleEndTime = oldValue
                        }
                    }
                    .onChange(of: isEndTimeOpen) { newValue in
                        if newValue {
                            isDateOpen = false
                            isStartTimeOpen = false
                        }
                    }
            }
        }
    }
}

#Preview {
    SinglePlanDateTimeSection(
        singleDate: .constant(Date()),
        singleStartTime: .constant(Date()),
        singleEndTime: .constant(Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()),
        onStartTimeChange: { newTime in
            print("시작 시간 변경: \(newTime)")
        }
    )
    .padding()
}
