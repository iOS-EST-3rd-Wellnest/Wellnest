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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("기간 설정")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                DatePicker("시작 날짜", selection: $multipleStartDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())

                DatePicker("종료 날짜", selection: $multipleEndDate, in: multipleStartDate..., displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())

                Divider()

                Text("운동 시간대")
                    .font(.subheadline)
                    .fontWeight(.medium)

                DatePicker("시작 시간", selection: $multipleStartTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(CompactDatePickerStyle())
                    .onChange(of: multipleStartTime) { newValue in
                        // 시작 시간이 변경되면 종료 시간을 1시간 후로 자동 설정
                        multipleEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                    }

                DatePicker("종료 시간", selection: $multipleEndTime, in: multipleStartTime..., displayedComponents: .hourAndMinute)
                    .datePickerStyle(CompactDatePickerStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    MultiplePlanDateTimeSection(
        multipleStartDate: .constant(Date()),
        multipleEndDate: .constant(Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()),
        multipleStartTime: .constant(Date()),
        multipleEndTime: .constant(Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date())
    )
    .padding()
}
