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
        HStack {
            VStack(alignment: .leading, spacing: Spacing.content) {
                Text(schedule.title)
                    .font(.headline)

                Text("\(schedule.startDate.formattedTime) ~ \(schedule.endDate.formattedTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color(.systemGray6))
        )
    }
}
