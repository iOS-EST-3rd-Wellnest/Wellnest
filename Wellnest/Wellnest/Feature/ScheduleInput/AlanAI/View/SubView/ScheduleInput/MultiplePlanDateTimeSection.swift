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
                DatePickerView(text: "시작", date: $multipleStartTime, isAllDay: .constant(false), isPresented: $isStartTimeOpen)
                    .tint(.wellnestOrange)
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
                    .tint(.wellnestOrange)
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
        .onAppear {
            let roundedNow = roundedUpToFiveMinutes(Date())
            let roundedEndTime = roundedUpToFiveMinutes(Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date())
            
            // 현재 값이 기본값(과거 시각)인 경우에만 업데이트
            if multipleStartTime < Date() {
                multipleStartTime = roundedNow
                onStartTimeChange(roundedNow)
                // 시작 날짜도 업데이트
                let calendar = Calendar.current
                multipleStartDate = calendar.startOfDay(for: roundedNow)
            }
            if multipleEndTime < multipleStartTime {
                multipleEndTime = roundedEndTime
                // 종료 날짜도 업데이트
                let calendar = Calendar.current
                multipleEndDate = calendar.startOfDay(for: roundedEndTime)
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
