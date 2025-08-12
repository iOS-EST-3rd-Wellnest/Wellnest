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
                    .opacity(0.75)
                
                Text("\(schedule.startDate.formattedTime) ~ \(schedule.endDate.formattedTime)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text(schedule.title)
                .font(.headline)
                .bold()
                .padding(.horizontal, Spacing.content)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color(.systemGray6))
                .defaultShadow()
        )
        .frame(height: 70)
    }
}
