//
//  WeekdayChip.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct WeekdayChip: View {
    let weekday: String
    let index: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(weekday)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .wellnestOrange : .primary)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.wellnestOrange.opacity(0.2) : Color.gray.opacity(0.1))
                .overlay(
                    Circle()
                        .stroke(isSelected ? .wellnestOrange : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .clipShape(Circle())
        }
    }
}

#Preview {
    HStack {
        WeekdayChip(weekday: "월", index: 1, isSelected: true) { }
        WeekdayChip(weekday: "화", index: 2, isSelected: false) { }
        WeekdayChip(weekday: "수", index: 3, isSelected: true) { }
        WeekdayChip(weekday: "목", index: 4, isSelected: false) { }
        WeekdayChip(weekday: "금", index: 5, isSelected: true) { }
    }
    .padding()
}
