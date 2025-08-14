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
                .fill(colorFromNamedColorDescription(schedule.backgroundColor))
                .defaultShadow()
        )
        .frame(height: 70)
    }
    
}

extension ScheduleItemView {
    private func colorFromNamedColorDescription(_ backgroundStr: String) -> Color {
        let pattern = #"NamedColor\(name:\s*"([^"]+)""#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: backgroundStr, range: NSRange(backgroundStr.startIndex..., in: backgroundStr)),
            let nameRange = Range(match.range(at: 1), in: backgroundStr)
        else {
            return Color(.systemGray6)
        }

        let name = String(backgroundStr[nameRange])
        
        if let ui = UIColor(named: name, in: .main, compatibleWith: nil) {
            return Color(uiColor: ui)
        } else {
            return Color(.systemGray6)
        }
    }
}
