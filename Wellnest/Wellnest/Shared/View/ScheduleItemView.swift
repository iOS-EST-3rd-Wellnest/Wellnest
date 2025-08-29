//
//  ScheduleRowView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import SwiftUI

struct ScheduleItemView: View {
    let schedule: ScheduleItem
    var contextDate: Date? = nil
    var showOnlyPlanView: Bool = true
    var onToggleComplete: ((ScheduleItem) -> Void)? = nil
    var isUpcomingGroup: Bool = false

    var body: some View {
        let display: ScheduleDayDisplay? = contextDate.map { schedule.display(on: $0) }
        let isAllDay = display?.isAllDayForThatDate ?? schedule.isAllDay
        let timeText: String = {
            if let d = display {
                if d.isAllDayForThatDate { return "하루 종일" }
                if let s = d.displayStart, let e = d.displayEnd {
                    return "\(s.formattedTime) - \(e.formattedTime)"
                }
                return ""
            } else {
                return isAllDay ? "하루 종일" : "\(schedule.startDate.formattedTime) - \(schedule.endDate.formattedTime)"
            }
        }()

        HStack(alignment: .center, spacing: Spacing.content) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.scheduleSolid(color: schedule.backgroundColor))
                .frame(width: 4)
                .padding(.leading, Spacing.inline)

            VStack(alignment: .leading, spacing: Spacing.inline) {
                HStack(spacing: Spacing.inline) {
                    Text(timeText)
                        .font(.subheadline)
                        .foregroundStyle(.gray)

                    if let repeatRule = schedule.repeatRule {
                        Text("• \(repeatRule)")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }

                    Group {
                        if schedule.hasAlarm {
                            Image(systemName: "bell.fill")
                                .font(.caption)
                                .foregroundStyle(Color.scheduleSolid(color: schedule.backgroundColor))
                        } else {
                            Image(systemName: "bell.slash.fill")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                }

                Text(schedule.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)

                if showOnlyPlanView {
                    if let memo = schedule.memo, !memo.isEmpty {
                        Text(memo)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.leading, Spacing.inline)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            if showOnlyPlanView {
                Button {
                    onToggleComplete?(schedule)
                } label: {
                    ZStack {
                        if schedule.isCompleted {
                            Circle()
                                .fill(schedule.isCompleted ? Color.scheduleSolid(color: schedule.backgroundColor) : .gray)
                                .frame(width: 28, height: 28)
                        } else {
                            Circle()
                                .stroke(schedule.isCompleted ? Color.scheduleSolid(color: schedule.backgroundColor) : .gray, lineWidth: 1)
                                .frame(width: 28, height: 28)
                        }
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(schedule.isCompleted ? .white : .gray)
                    }
                }
                .buttonStyle(.plain)
            }

        }
        .padding(Spacing.content)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .fill(showOnlyPlanView && isUpcomingGroup && !isAllDay ? Color.scheduleBackground(color: schedule.backgroundColor) : .clear)
        }
        .overlay {
            Group {
                if showOnlyPlanView && isUpcomingGroup || isAllDay {
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .stroke(Color.scheduleSolid(color: schedule.backgroundColor), lineWidth: 1)
                } else {
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .stroke(.secondary.opacity(0.5), lineWidth: 0.5)
                }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }
}

#Preview {
    VStack(spacing: Spacing.content) {
        ScheduleItemView(
            schedule: ScheduleItem(
                id: UUID(),
                title: "팀 미팅",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date(),
                createdAt: Date(),
                updatedAt: Date(),
                backgroundColor: "blue",
                isAllDay: false,
                repeatRule: "매주",
                hasRepeatEndDate: false,
                repeatEndDate: nil,
                isCompleted: false,
                eventIdentifier: nil,
                location: nil,
                alarm: "10분 전",
                memo: nil
            )
        )


        ScheduleItemView(
            schedule: ScheduleItem(
                id: UUID(),
                title: "휴가",
                startDate: Date(),
                endDate: Date(),
                createdAt: Date(),
                updatedAt: Date(),
                backgroundColor: "green",
                isAllDay: true,
                repeatRule: nil,
                hasRepeatEndDate: false,
                repeatEndDate: nil,
                isCompleted: true,
                eventIdentifier: nil,
                location: nil,
                alarm: nil, memo: nil
            )
        )


        ScheduleItemView(
            schedule: ScheduleItem(
                id: UUID(),
                title: "아주 긴 제목을 가진 일정입니다. 이렇게 길어도 잘 표시되는지 확인해보겠습니다.",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date(),
                createdAt: Date(),
                updatedAt: Date(),
                backgroundColor: "purple",
                isAllDay: false,
                repeatRule: "매일",
                hasRepeatEndDate: false,
                repeatEndDate: nil,
                isCompleted: true,
                eventIdentifier: nil,
                location: nil,
                alarm: "1시간 전",
                memo: nil
            )
        )

    }
    .padding()
}
