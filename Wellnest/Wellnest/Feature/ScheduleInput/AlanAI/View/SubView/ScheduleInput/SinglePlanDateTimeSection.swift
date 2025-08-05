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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("일정 설정")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                DatePicker("날짜", selection: $singleDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())

                DatePicker("시작 시간", selection: $singleStartTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(CompactDatePickerStyle())
                    .onChange(of: singleStartTime) { newValue in
                        // 시작 시간이 변경되면 종료 시간을 1시간 후로 자동 설정
                        singleEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                    }

                DatePicker("종료 시간", selection: $singleEndTime, in: singleStartTime..., displayedComponents: .hourAndMinute)
                    .datePickerStyle(CompactDatePickerStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    SinglePlanDateTimeSection(
        singleDate: .constant(Date()),
        singleStartTime: .constant(Date()),
        singleEndTime: .constant(Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date())
    )
    .padding()
}
