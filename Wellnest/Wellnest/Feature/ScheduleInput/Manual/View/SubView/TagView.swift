//
//  TagView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import SwiftUI

struct TagView<Model: TagModel>: View {
    let tag: Model
    var isSelected: Bool = false

    var body: some View {
        Text(tag.name)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, Spacing.layout)
            .padding(.vertical, Spacing.content)
            .background(isSelected ? Color.wellnestOrange.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .wellnestOrange : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(isSelected ? .wellnestOrange : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(16)
    }
}

struct Tag: Identifiable, Hashable {
    let id = UUID()
    let name: String
}
