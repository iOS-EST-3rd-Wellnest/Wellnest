//
//  SchedulesSection.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct SchedulesSection: View {
    let schedules: [AIScheduleItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("일정")
                .font(.title3)
                .fontWeight(.bold)

            ForEach(schedules) { schedule in
                ScheduleCard(schedule: schedule)
            }
        }
    }
}

#Preview {
    SchedulesSection(
        schedules: [
            AIScheduleItem(
                day: "월요일",
                date: nil,
                time: "09:00 - 10:00",
                activity: "상체 근력 운동",
                notes: "벤치프레스, 덤벨 플라이 위주로 진행"
            ),
            AIScheduleItem(
                day: nil,
                date: "2025-08-05",
                time: "14:00 - 15:30",
                activity: "요가 클래스",
                notes: "초보자 클래스 추천"
            )
        ]
    )
    .padding()
}
