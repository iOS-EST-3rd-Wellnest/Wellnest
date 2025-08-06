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
    
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("루틴 설정")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 16) {
                // 요일 선택
                VStack(alignment: .leading, spacing: 8) {
                    Text("요일 선택")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(0..<7, id: \.self) { index in
                            WeekdayChip(
                                weekday: weekdays[index],
                                index: index,
                                isSelected: selectedWeekdays.contains(index)
                            ) {
                                if selectedWeekdays.contains(index) {
                                    selectedWeekdays.remove(index)
                                } else {
                                    selectedWeekdays.insert(index)
                                }
                            }
                        }
                    }
                }

                Divider()

                // 운동 시간대
                VStack(alignment: .leading, spacing: 8) {
                    Text("운동 시간대")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    DatePicker("시작 시간", selection: $routineStartTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(CompactDatePickerStyle())
                        .onChange(of: routineStartTime) { newValue in
                            // 시작 시간이 변경되면 종료 시간을 1시간 후로 자동 설정
                            routineEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                        }

                    DatePicker("종료 시간", selection: $routineEndTime, in: routineStartTime..., displayedComponents: .hourAndMinute)
                        .datePickerStyle(CompactDatePickerStyle())
                }

                Divider()

                // 루틴 기간
                VStack(alignment: .leading, spacing: 8) {
                    Text("루틴 기간")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    DatePicker("시작 날짜", selection: $routineStartDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())

                    DatePicker("종료 날짜", selection: $routineEndDate, in: routineStartDate..., displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    RoutinePlanDateTimeSection(
        selectedWeekdays: .constant(Set([1, 3, 5])),
        routineStartDate: .constant(Date()),
        routineEndDate: .constant(Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()),
        routineStartTime: .constant(Date()),
        routineEndTime: .constant(Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date())
    )
    .padding()
}
