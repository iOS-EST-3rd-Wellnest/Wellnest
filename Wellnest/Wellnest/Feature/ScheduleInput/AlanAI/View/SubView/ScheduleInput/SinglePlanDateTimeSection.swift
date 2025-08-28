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
    
    private func roundedUpToFiveMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = components.minute ?? 0
        let remainder = minute % 5
        let minutesToAdd = remainder == 0 ? 0 : (5 - remainder)
        return calendar.date(byAdding: .minute, value: minutesToAdd, to: date) ?? date
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.layout) {
            Text("일정 설정")
                .font(.headline)
                .fontWeight(.semibold)

            VStack {
                DatePickerView(text: "시작", date: $singleStartTime, isAllDay: .constant(false), isPresented: $isStartTimeOpen)
                    .tint(.wellnestOrange)
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
                    .tint(.wellnestOrange)
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
        .onAppear {
            let roundedNow = roundedUpToFiveMinutes(Date())
            let roundedEndTime = roundedUpToFiveMinutes(Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date())
            
            // 현재 값이 기본값(과거 시각)인 경우에만 업데이트
            if singleStartTime < Date() {
                singleStartTime = roundedNow
                onStartTimeChange(roundedNow)
            }
            if singleEndTime < singleStartTime {
                singleEndTime = roundedEndTime
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
