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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(20)
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
