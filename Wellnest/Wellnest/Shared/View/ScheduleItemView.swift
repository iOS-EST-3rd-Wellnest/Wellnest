//
//  ScheduleRowView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import SwiftUI

struct ScheduleItemView: View {
    let schedule: ScheduleItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.content) {
            HStack {
                Image(systemName: "clock.fill")

                if schedule.isAllDay {
                     Text("하루 종일")
                         .font(.footnote)
                 } else {
                     Text("\(schedule.startDate.formattedTime) ~ \(schedule.endDate.formattedTime)")
                         .font(.footnote)
                 }

                Spacer()

                if schedule.isCompleted {
                      Image(systemName: "checkmark.circle.fill")
                          .foregroundStyle(.black)
                          .font(.title2)
                  }
            }
            
            HStack {
                Text(schedule.title)
                    .font(.headline)
                    .bold()

                Spacer()
                
                if let repeatRule = schedule.repeatRule {
                    Text(repeatRule)
                        .font(.caption2)
                        .padding(.horizontal, Spacing.content)
                        .background {
                            Capsule()
                                .fill(.secondary.opacity(0.3))
                        }
                }
            }
        }
        .padding()
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color.scheduleSolid(color: schedule.backgroundColor))
                .defaultShadow()
        )
    }
}

#Preview {
    PlanView(selectedTab: .constant(.plan), selectedCreationType: .constant(.createByUser))
}
