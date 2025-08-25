//
//  PreferenceChip.swift
//  Wellnest
//
//  Created by junil on 8/5/25.
//

import SwiftUI

struct PreferenceChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, Spacing.layout)
                .padding(.vertical, Spacing.content)
                .background(isSelected ? Color.wellnestOrange : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .stroke(isSelected ? Color.wellnestOrange : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(CornerRadius.large)
        }
    }
}

#Preview {
    VStack {
        HStack {
            PreferenceChip(title: "유산소", isSelected: true) { }
            PreferenceChip(title: "근력운동", isSelected: false) { }
        }
        HStack {
            PreferenceChip(title: "요가", isSelected: false) { }
            PreferenceChip(title: "필라테스", isSelected: true) { }
        }
    }
    .padding()
}
