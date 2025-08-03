//
//  TagView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import SwiftUI

/// 단일 태그를 시각적으로 표현하는 뷰
struct TagView<Model: TagModel>: View {

    /// 렌더링할 태그 모델
    let tag: Model

    /// 선택 상태 여부 (선택되었을 경우 스타일 변경)
    var isSelected: Bool = false

    var body: some View {
        Text(tag.name)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, Spacing.layout)
            .padding(.vertical, Spacing.content)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .blue : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(16)
    }
}

struct Tag: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

