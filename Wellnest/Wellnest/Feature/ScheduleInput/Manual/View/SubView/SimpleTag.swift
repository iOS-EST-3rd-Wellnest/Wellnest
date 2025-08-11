//
//  SimpleTag.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/11/25.
//

import SwiftUI

struct SimpleTag: View {
    var text: String
    var isSelected: Bool = false

    init(_ text: String, isSelected: Bool = false) {
        self.text = text
        self.isSelected = isSelected
    }

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .blue : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
    }
}
