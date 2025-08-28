//
//  RoutinePlanDateTimeSection.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct RoutinePlanDateTimeSection: View {
    @Binding var selectedWeekdays: Set<Int>
    @Binding var routineStartDate: Date
    @Binding var routineEndDate: Date
    @Binding var routineStartTime: Date
    @Binding var routineEndTime: Date
    let onWeekdayToggle: (Int) -> Void
    let onStartTimeChange: (Date) -> Void

    @State private var isStartDateOpen = false
    @State private var isEndDateOpen = false
    @State private var isStartTimeOpen = false
    @State private var isEndTimeOpen = false

    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.layout) {
            Text("루틴 설정")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: Spacing.layout) {
                // 요일 선택
                VStack(alignment: .leading, spacing: Spacing.content) {

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.content) {
                        ForEach(0..<7, id: \.self) { index in
                            WeekdayChip(
                                weekday: weekdays[index],
                                index: index,
                                isSelected: selectedWeekdays.contains(index)
                            ) {
                                onWeekdayToggle(index)
                            }
                        }
                    }
                }

                Divider()

                // 시간대
                VStack(alignment: .leading, spacing: Spacing.content) {

                    TimePickerView(text: "시작 시간", time: $routineStartTime, isPresented: $isStartTimeOpen)
                        .onChange(of: routineStartTime) { newValue in
                            onStartTimeChange(newValue)
                        }
                        .onChange(of: isStartTimeOpen) { newValue in
                            if newValue {
                                isStartDateOpen = false
                                isEndDateOpen = false
                                isEndTimeOpen = false
                            }
                        }

                    TimePickerView(text: "종료 시간", time: $routineEndTime, isPresented: $isEndTimeOpen)
                        .onChangeWithOldValue(of: routineEndTime) { oldValue, newValue in
                            if newValue.timeIntervalSince(routineStartTime) < 0 {
                                routineEndTime = oldValue
                            }
                        }
                        .onChange(of: isEndTimeOpen) { newValue in
                            if newValue {
                                isStartDateOpen = false
                                isEndDateOpen = false
                                isStartTimeOpen = false
                            }
                        }
                }

                Divider()

                // 루틴 기간
                VStack(alignment: .leading, spacing: Spacing.content) {
                    DatePickerView(text: "시작 날짜", date: $routineStartDate, isAllDay: .constant(true), isPresented: $isStartDateOpen)
                        .tint(.wellnestOrange)
                        .onChange(of: isStartDateOpen) { newValue in
                            if newValue {
                                isEndDateOpen = false
                                isStartTimeOpen = false
                                isEndTimeOpen = false
                            }
                        }

                    DatePickerView(text: "종료 날짜", date: $routineEndDate, isAllDay: .constant(true), isPresented: $isEndDateOpen)
                        .tint(.wellnestOrange)
                        .onChangeWithOldValue(of: routineEndDate) { oldValue, newValue in
                            if newValue.timeIntervalSince(routineStartDate) < 0 {
                                routineEndDate = oldValue
                            }
                        }
                        .onChange(of: isEndDateOpen) { newValue in
                            if newValue {
                                isStartDateOpen = false
                                isStartTimeOpen = false
                                isEndTimeOpen = false
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    RoutinePlanDateTimeSection(
        selectedWeekdays: .constant(Set([1, 3, 5])), // 월, 수, 금 선택
        routineStartDate: .constant(Date()),
        routineEndDate: .constant(Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()),
        routineStartTime: .constant(Date()),
        routineEndTime: .constant(Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()),
        onWeekdayToggle: { weekdayIndex in
            print("요일 토글: \(weekdayIndex)")
        },
        onStartTimeChange: { newTime in
            print("시작 시간 변경: \(newTime)")
        }
    )
    .padding()
}
