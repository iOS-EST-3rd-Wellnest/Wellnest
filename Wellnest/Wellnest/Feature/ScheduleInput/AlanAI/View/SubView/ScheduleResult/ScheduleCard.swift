//
//  ScheduleCard.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct ScheduleCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let schedule: AIScheduleItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let day = schedule.day {
                        Text(day)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(.wellnestOrange))
                    } else if let date = schedule.date {
                        Text(date)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(.wellnestOrange))
                    }

                    Text(schedule.time)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(schedule.activity)
                    .font(.headline)
                    .fontWeight(.semibold)

                if let notes = schedule.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5))
        .roundedBorder(cornerRadius: 12)
        .defaultShadow()
    }
}

#Preview {
    VStack(spacing: 16) {
        ScheduleCard(
            schedule: AIScheduleItem(
                day: "월요일",
                date: nil,
                time: "09:00 - 10:00",
                activity: "상체 근력 운동",
                notes: "벤치프레스, 덤벨 플라이 위주로 진행"
            )
        )

        ScheduleCard(
            schedule: AIScheduleItem(
                day: nil,
                date: "2025-08-05",
                time: "14:00 - 15:30",
                activity: "요가 클래스",
                notes: "초보자 클래스 추천"
            )
        )
    }
    .padding()
}
