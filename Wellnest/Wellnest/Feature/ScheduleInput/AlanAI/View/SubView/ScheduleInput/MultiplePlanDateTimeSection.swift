//
//  MultiplePlanDateTimeSection.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct MultiplePlanDateTimeSection: View {
    @Binding var multipleStartDate: Date
    @Binding var multipleEndDate: Date
    @Binding var multipleStartTime: Date
    @Binding var multipleEndTime: Date
    let onStartTimeChange: (Date) -> Void

    @State private var isStartTimeOpen = false
    @State private var isEndTimeOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.layout) {
            Text("일정 설정")
                .font(.headline)
                .fontWeight(.semibold)

            VStack {
                DatePickerView(text: "시작", date: $multipleStartTime, isAllDay: .constant(false), isPresented: $isStartTimeOpen)
                    .onChange(of: multipleStartTime) { newValue in
                        onStartTimeChange(newValue)
                        // 시작 날짜/시간에서 날짜 추출해서 multipleStartDate에 설정
                        let calendar = Calendar.current
                        multipleStartDate = calendar.startOfDay(for: newValue)
                    }
                    .onChange(of: isStartTimeOpen) { newValue in
                        if newValue {
                            isEndTimeOpen = false
                        }
                    }

                DatePickerView(text: "종료", date: $multipleEndTime, isAllDay: .constant(false), isPresented: $isEndTimeOpen)
                    .onChange(of: multipleEndTime) { newValue in
                        // 종료 날짜/시간에서 날짜 추출해서 multipleEndDate에 설정
                        let calendar = Calendar.current
                        multipleEndDate = calendar.startOfDay(for: newValue)
                    }
                    .onChangeWithOldValue(of: multipleEndTime) { oldValue, newValue in
                        if newValue.timeIntervalSince(multipleStartTime) < 0 {
                            multipleEndTime = oldValue
                        }
                    }
                    .onChange(of: isEndTimeOpen) { newValue in
                        if newValue {
                            isStartTimeOpen = false
                        }
                    }
            }
        }
    }
}

#Preview {
    MultiplePlanDateTimeSection(
        multipleStartDate: .constant(Date()),
        multipleEndDate: .constant(Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()),
        multipleStartTime: .constant(Date()),
        multipleEndTime: .constant(Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()),
        onStartTimeChange: { newTime in
            print("시작 시간 변경: \(newTime)")
        }
    )
    .padding()
}
